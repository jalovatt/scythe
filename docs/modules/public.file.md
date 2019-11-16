<section class="segment">

###  <a name="File.files">File.files(path[, idx])</a>

An iterator that loops over the files in a specified path.

| **Required** | []() | []() |
| --- | --- | --- |
| path | string | A folder |

| **Returns** | []() |
| --- | --- |
| iterator |  |

</section>
<section class="segment">

###  <a name="File.folders">File.folders(path[, idx])</a>

An iterator that loops over the folders in a specified path.

| **Required** | []() | []() |
| --- | --- | --- |
| path | string | A folder |

| **Returns** | []() |
| --- | --- |
| iterator |  |

</section>
<section class="segment">

###  <a name="File.getFiles">File.getFiles(path[, filter])</a>

Collects the files in a specified path, with optional filtering.

| **Required** | []() | []() |
| --- | --- | --- |
| path | string | A folder |

| **Optional** | []() | []() |
| --- | --- | --- |
| filter | function | Used to filter the included files. If `filter(file)` is falsy, a file will not be included. |

| **Returns** | []() |
| --- | --- |
| array | Files, of the form `{ name = "file.name", path = "fullpath/file.name" }` |

</section>
<section class="segment">

###  <a name="File.getFolders">File.getFolders(path[, filter])</a>

Collects the folders in a specified path, with optional filtering.

| **Required** | []() | []() |
| --- | --- | --- |
| path | string | A folder |

| **Optional** | []() | []() |
| --- | --- | --- |
| filter | function | Used to filter the included folder. If `filter(fullpath)` is falsy, a folder will not be included. |

| **Returns** | []() |
| --- | --- |
| array | Folders, of the form `{ name = "folder", path = "fullpath/folder" }` |

</section>
<section class="segment">

###  <a name="File.getFilesRecursive">File.getFilesRecursive(path[, filter, acc])</a>

Collects all of the files in a specified path, recursing through any subfolders,
with optional filtering.

| **Required** | []() | []() |
| --- | --- | --- |
| path | string | A folder |

| **Optional** | []() | []() |
| --- | --- | --- |
| filter | function | Used to filter the included files. If `filter(name, fullpath)` is falsy, a file will not be included. When subfolders are present, they will be skipped if `filter(name, fullpath, isFolder = true)` is falsy. |

| **Returns** | []() |
| --- | --- |
| array | Files, of the form `{ name = "file.name", path = "fullpath/file.name" }` |

</section>
<section class="segment">

###  <a name="File.ensurePathExists">File.ensurePathExists(path)</a>

Checks if a given path exists, creating any missing folders if necessary

| **Required** | []() | []() |
| --- | --- | --- |
| path | string | A folder path |

| **Returns** | []() |
| --- | --- |
| boolean | Returns `true` if successful, otherwise `nil` |

</section>