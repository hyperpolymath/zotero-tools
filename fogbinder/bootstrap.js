// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
//
// @file bootstrap.js
// @description Zotero 7/8 Bootstrapped Add-on entry point for Fogbinder.
//              Loads the ReScript-compiled Fogbinder module.
//              Follows the ZoteRho Template bootstrap pattern.

"use strict";

var Fogbinder;

function log(msg) {
  Zotero.debug("Fogbinder: " + msg);
}

function install() {
  log("Installed 0.1.0");
}

async function startup({ id, version, rootURI }) {
  log("Starting 0.1.0");

  // Load the main ReScript-compiled module
  Services.scriptloader.loadSubScript(rootURI + "Fogbinder.js");

  Fogbinder.init({ id, version, rootURI });
  Fogbinder.addToAllWindows();
  await Fogbinder.main();
}

function onMainWindowLoad({ window }) {
  Fogbinder.addToWindow({ window });
}

function onMainWindowUnload({ window }) {
  Fogbinder.removeFromWindow({ window });
}

function shutdown() {
  log("Shutting down");
  Fogbinder.removeFromAllWindows();
}

function uninstall() {
  log("Uninstalled");
}
