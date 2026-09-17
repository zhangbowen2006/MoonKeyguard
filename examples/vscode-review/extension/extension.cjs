// Original, development-only consumer fixture. Never installs itself.
const vscode = require('vscode');

async function activate(context) {
  let wrapMode = false;
  await vscode.commands.executeCommand('setContext', 'keyguard.wrapMode', false);
  context.subscriptions.push(
    vscode.commands.registerCommand('keyguard.toggleWrapMode', async () => {
      wrapMode = !wrapMode;
      await vscode.commands.executeCommand('setContext', 'keyguard.wrapMode', wrapMode);
      vscode.window.showInformationMessage('Keyguard demo wrap mode: ' + (wrapMode ? 'on' : 'off'));
    }),
    vscode.commands.registerCommand('keyguard.wrapSelection', async () => {
      const editor = vscode.window.activeTextEditor;
      if (!wrapMode || !editor || editor.selection.isEmpty) return;
      const selection = editor.selection;
      const text = editor.document.getText(selection);
      await editor.edit(edit => edit.replace(selection, '[' + text + ']'));
    }),
  );
}

exports.activate = activate;
