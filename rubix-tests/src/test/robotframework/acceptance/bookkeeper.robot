*** Settings ***
Library  Collections
Library  com.qubole.rubix.client.robotframework.BookKeeperClientRFLibrary

*** Keywords ***

## Generation ##

Generate single test file
    [Documentation]  Generate a test file with the given name and length.
    [Arguments]  ${fileName}  ${fileLength}
    generate Test File  ${fileName}  ${fileLength}
    [Return]  ${fileName}

Generate test files
    [Documentation]  Generate similar test files with the given file prefix and length.
    [Arguments]  ${filePrefix}
    ...          ${fileLength}
    ...          ${numFiles}
    ...          ${offset}=0
    @{testFileNames} =  CREATE LIST
    :FOR  ${index}  IN RANGE  ${offset}  ${numFiles}
    \  ${fileName} =  SET VARIABLE  ${filePrefix}${index}
    \  generate Test File  ${fileName}  ${fileLength}
    \  APPEND TO LIST  ${testFileNames}  ${fileName}
    [Return]  @{testFileNames}

Make read request
    [Documentation]  Create a read request used to cache data for the provided file.
    [Arguments]  ${fileName}
    ...          ${startBlock}
    ...          ${endBlock}
    ...          ${fileLength}
    ...          ${lastModified}
    ...          ${clusterType}
    ${request} =  create Test Client Read Request
    ...  file://${fileName}
    ...  ${startBlock}
    ...  ${endBlock}
    ...  ${fileLength}
    ...  ${lastModified}
    ...  ${clusterType}
    [Return]  ${request}

Make similar read requests
    [Documentation]  Create read requests with similar properties for the provided files.
    [Arguments]  ${fileNames}
    ...          ${startBlock}
    ...          ${endBlock}
    ...          ${fileLength}
    ...          ${lastModified}
    ...          ${clusterType}
    @{requests} =  CREATE LIST
    :FOR  ${fileName}  IN  @{fileNames}
    \   ${request} =  create Test Client Read Request
    ...  file://${fileName}
    ...  ${startBlock}
    ...  ${endBlock}
    ...  ${fileLength}
    ...  ${lastModified}
    ...  ${clusterType}
    \   APPEND TO LIST  ${requests}  ${request}
    [Return]  @{requests}

## Execution ##

Execute concurrent requests
    [Documentation]  Using the provided keyword, execute the requests concurrently on the specified number of threads.
    [Arguments]  ${executionKeyword}
    ...          ${numThreads}
    ...          ${requests}
    ...          ${staggerRequests}=false
    RUN KEYWORD  ${executionKeyword}
    ...  ${numThreads}
    ...  ${requests}
    ...  ${staggerRequests}

Execute sequential requests
    [Documentation]  Using the provided keyword, execute the requests sequentially.
    [Arguments]  ${executionKeyword}  ${requests}
    :FOR  ${request}  IN  @{requests}
    \  RUN KEYWORD  ${executionKeyword}  ${request}

Execute read request using BookKeeper server call
    [Documentation]  Execute the read request by directly calling the BookKeeper server.
    [Arguments]  ${readRequest}
    ${didRead} =  cache Data Using BookKeeper Server Call  ${readRequest}
    SHOULD BE TRUE  ${didRead}

Concurrently execute read requests using BookKeeper server call
    [Documentation]  Execute the read requests concurrently by directly calling the BookKeeper server.
    [Arguments]  ${numThreads}  ${readRequests}  ${staggerRequests}
    ${didReadAll} =  concurrently Cache Data Using BookKeeper Server Call  ${numThreads}  ${staggerRequests}  @{readRequests}
    SHOULD BE TRUE  ${didReadAll}

Execute read request using client file system
    [Documentation]  Execute the read request by using a client-side CachingFileSystem.
    [Arguments]  ${readRequest}
    ${didRead} =  cache Data Using Client File System  ${readRequest}
    SHOULD BE TRUE  ${didRead}

Concurrently execute read requests using client file system
    [Documentation]  Execute the read requests concurrently by using a client-side CachingFileSystem.
    [Arguments]  ${numThreads}  ${readRequests}  ${staggerRequests}
    ${didReadAll} =  concurrently Cache Data Using Client File System  ${numThreads}  ${staggerRequests}  @{readRequests}
    SHOULD BE TRUE  ${didReadAll}

## Verification ##

Verify cache directory size
    [Documentation]  Verify that the cache directory is the expected size.
    [Arguments]  ${cachePrefix}
    ...          ${cacheSuffix}
    ...          ${cacheNumDisks}
    ...          ${expectedCacheSize}
    ${cacheDirSize} =  get Cache Dir Size MB  ${cachePrefix}  ${cacheSuffix}  ${cacheNumDisks}
    SHOULD BE EQUAL AS INTEGERS  ${cacheDirSize}  ${expectedCacheSize}

Verify metric value
    [Documentation]  Verify that the BookKeeper server is reporting the expected metric value.
    [Arguments]  ${metricName}  ${expectedValue}
    &{metrics} =  get Cache Metrics
    LOG MANY  &{metrics}
    SHOULD NOT BE EMPTY  ${metrics}
    SHOULD BE EQUAL AS NUMBERS  &{metrics}[${metricName}]  ${expectedValue}
