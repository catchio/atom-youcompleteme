os = require 'os'
path = require 'path'
{File, Point} = require 'atom'

getEditorTmpFilepath = (editor) ->
  return path.resolve os.tmpdir(), "AtomYcmBuffer-#{editor.getBuffer().getId()}"

getEditorData = (editor = atom.workspace.getActiveTextEditor(), scopeDescriptor = editor.getRootScopeDescriptor()) ->
  filepath = editor.getPath()
  contents = editor.getText()
  filetypes = getScopeFiletypes scopeDescriptor
  bufferPosition = editor.getCursorBufferPosition()
  if filepath?
    return Promise.resolve {filepath, contents, filetypes, bufferPosition}
  else
    return new Promise (fulfill, reject) ->
      filepath = getEditorTmpFilepath editor
      file = new File filepath
      file.write contents
        .then -> fulfill {filepath, contents, filetypes, bufferPosition}
        .catch (error) -> reject error

getScopeFiletypes = (scopeDescriptor = atom.workspace.getActiveTextEditor().getRootScopeDescriptor()) ->
  return scopeDescriptor.getScopesArray().map (scope) -> scope.split('.').pop()

buildRequestParameters = (filepath, contents, filetypes = [], bufferPosition = new Point(0, 0)) ->
  parameters =
    filepath: filepath
    line_num: bufferPosition.row + 1
    column_num: bufferPosition.column + 1
    file_data: {}
  parameters.file_data[filepath] = {contents, filetypes}
  atom.workspace.getTextEditors()
    .filter (editor) -> editor.isModified() and editor.getPath()? and editor.getPath() isnt filepath
    .forEach (editor) -> parameters.file_data[editor.getPath()] =
      contents: editor.getText()
      filetypes: getScopeFiletypes editor.getRootScopeDescriptor()
  return parameters

isEnabledForScope = (scopeDescriptor) ->
  enabledFiletypes = atom.config.get('you-complete-me.enabledFiletypes').split(',').map (filetype) -> filetype.trim()
  filetypes = getScopeFiletypes scopeDescriptor
  filetype = filetypes.find (filetype) -> enabledFiletypes.indexOf(filetype) >= 0
  return if filetype? then true else false

module.exports =
  getEditorTmpFilepath: getEditorTmpFilepath
  getEditorData: getEditorData
  getScopeFiletypes: getScopeFiletypes
  buildRequestParameters: buildRequestParameters
  isEnabledForScope: isEnabledForScope
