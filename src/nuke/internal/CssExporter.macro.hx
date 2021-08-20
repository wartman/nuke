package nuke.internal;

import sys.io.File;
import haxe.macro.Context;
import haxe.macro.Compiler;
import nuke.injector.StaticInjector;

using haxe.io.Path;

class CssExporter {
  static var isInitialized:Bool = false;

  public static function shouldExport() {
    if (Context.defined('nuke.output')) {
      requestExport();
      return true;
    }
    return false;
  }

  static function requestExport() {
    if (!isInitialized) {
      isInitialized = true;
      Engine.setInstance(new Engine(new StaticInjector()));
      Context.onAfterGenerate(() -> {
        File.saveContent(getFilename(), Engine.getInstance().stylesToString());
      });
    }
  }

  static function getFilename() {
    return switch Context.definedValue('nuke.output') {
      case abs = _.charAt(0) => '.' | '/': abs.withExtension('css');
      case relative:
        Path.join([
          sys.FileSystem.absolutePath(Compiler.getOutput().directory()),
          relative
        ]).withExtension('css');
    }
  } 
}
