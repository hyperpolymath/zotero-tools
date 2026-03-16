// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
//
// @file bootstrap.js
// @description Zotero 7/8 Bootstrapped Add-on entry point for Voyant Export.
//              Loads the ReScript-compiled VoyantExport module.
//              Follows the ZoteRho Template bootstrap pattern.

"use strict";

var VoyantExport;

function log(msg) {
  Zotero.debug("Voyant Export: " + msg);
}

function install() {
  log("Installed 2.1.0");
}

async function startup({ id, version, rootURI }) {
  log("Starting 2.1.0");

  // Load the main ReScript-compiled module
  Services.scriptloader.loadSubScript(rootURI + "VoyantExport.js");

  VoyantExport.init({ id, version, rootURI });
  VoyantExport.addToAllWindows();
  await VoyantExport.main();
}

function onMainWindowLoad({ window }) {
  VoyantExport.addToWindow({ window });
}

function onMainWindowUnload({ window }) {
  VoyantExport.removeFromWindow({ window });
}

function shutdown() {
  log("Shutting down");
  VoyantExport.removeFromAllWindows();
}

function uninstall() {
  log("Uninstalled");
}
