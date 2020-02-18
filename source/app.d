import std.stdio,
       std.process,
       std.typecons,
       std.file,
       std.path,
       std.json,
       std.format,
       std.algorithm,
       std.array,
       std.exception;

class UnimplementedException : Exception { this (string msg) { super(msg); } }
class DBKException : Exception { this (string msg) { super(msg); } }

class Env {
  string home;

  this() {
    this.home = environment.get("HOME");
  }
}

enum BookmarksFileName = "bookmarks.json";

class BookmarkEntry {
  string name;
  string path;

  this (string name, string path) {
    this.name = name;
    this.path = path;
  }
}

string getDBKHome(Env env) {
  return "%s/.dbk".format(env.home);
}

string getBookmarksFilePath(Env env) {
  return "%s/%s".format(env.getDBKHome, BookmarksFileName);
}

void writeBookmarksFile(Env env, string content) {
  File fp = File(getBookmarksFilePath(env), "w");
  fp.writeln(content);
}

void createBookmarksFile(Env env) {
  string content = `{
  "bookmarks" : []
}`;

  writeBookmarksFile(env, content);
}

void init(Env env) {
  string dbkHome = getDBKHome(env);

  if (!exists(dbkHome)) {
    mkdir(dbkHome);
  }

  string bookmarksFilePath = getBookmarksFilePath(env);

  if (!exists(bookmarksFilePath)) {
    createBookmarksFile(env);
  }
}

BookmarkEntry[] getAllBookmarks(Env env) {
  string bookmarksFilePath = getBookmarksFilePath(env);

  if (!exists(bookmarksFilePath)) {
    return [];
  }

  BookmarkEntry[] bookmarks;

  auto parsed = readText(bookmarksFilePath).parseJSON;

  foreach (JSONValue elem; parsed.object["bookmarks"].array) {
    bookmarks ~= new BookmarkEntry(elem.object["name"].str, elem.object["path"].str);
  }

  return bookmarks;
}

bool existsBookmarkEntry(Env env, string name) {
  return env.getAllBookmarks.any!(entry => name == entry.name);
}

Nullable!BookmarkEntry getBookmarkEntry(Env env, string name) {
  foreach (bookmark; getAllBookmarks(env)) {
    if (bookmark.name == name) {
      return nullable(bookmark);
    }
  }

  return typeof(return).init;
}

void add(Env env, Nullable!string optName, Nullable!string optPath) {
  string pwd = getcwd;
  string name = optName.isNull ? pwd.baseName : optName.get;
  string path = optPath.isNull ? pwd : optPath.get.expandTilde.absolutePath(pwd).buildNormalizedPath;

  if (existsBookmarkEntry(env, name)) {
    writefln("Error - Bookmark entry \"%s\" is already exists, please consider renaming", name);
  } else {
    writefln("New bookmark entry was just registered : %s - %s", name, path);

    JSONValue jentry;
    jentry["name"] = name;
    jentry["path"] = path;

    auto parsed = readText(getBookmarksFilePath(env)).parseJSON;
    parsed["bookmarks"].array ~= jentry;

    writeBookmarksFile(env, parsed.toJSON);
  }
}

void list(Env env) {
  BookmarkEntry[] bookmarks = getAllBookmarks(env);

  writeln("Bookmark List:");
  foreach (bookmark; bookmarks) {
    writefln("* %s - %s", bookmark.name, bookmark.path);
  }
}

void get(Env env, string name) {
  Nullable!BookmarkEntry optEntry = getBookmarkEntry(env, name);

  if (optEntry.isNull) {
    writefln("Error - No such a bookmark entry : %s", name);
  } else {
    writeln(optEntry.get.path);
  }
}

void rm(Env env, string name) {
  Nullable!BookmarkEntry optEntry = getBookmarkEntry(env, name);

  if (optEntry.isNull) {
    writefln("Error - No such a bookmark entry : %s", name);
  } else {
    BookmarkEntry[] bookmarks = getAllBookmarks(env);

    JSONValue jv = readText(getBookmarksFilePath(env)).parseJSON;
    jv["bookmarks"].array = [];

    foreach (bookmark; bookmarks) {
      if (bookmark.name == name) { continue; }
      JSONValue jentry;
      jentry["name"] = bookmark.name;
      jentry["path"] = bookmark.path;
      jv["bookmarks"].array ~= jentry;
    }

    writeBookmarksFile(env, jv.toJSON);
  }
}

void truncArg(ref string[] args) { args = args[1..$]; }

enum Command {
  Add = "add",
  List = "list",
  Get = "get",
  Goto = "goto",
  Rm = "rm"
}

void help() {
  writeln("[Help] - Supported Sub Commands are");

  foreach (cmd; __traits(allMembers, Command)) {
    mixin("string cmd_str = Command.%s;".format(cmd));
    writefln(" - %s", cmd_str);
  }
}

void main(string[] args) {
  args.truncArg;
  Env env = new Env;

  init(env);

  if (args.length) {
    switch (args[0]) with (Command) {
      case Add:
        args.truncArg;
        add(env,
            args.length      ? nullable(args[0]) : Nullable!string.init,
            args.length == 2 ? nullable(args[1]) : Nullable!string.init);
        break;
      case List:
        list(env);
        break;
      case Get:
        if (args.length < 2) { throw new DBKException("%s command error : Arguments required".format(args[0])); }
        args.truncArg;
        get(env, args[0]);
        break;
      case Goto:
        if (args.length < 2) { throw new DBKException("%s command error : Arguments required".format(args[0])); }
        args.truncArg;
        get(env, args[0]);
        break;
      case Rm:
        if (args.length < 2) { throw new DBKException("%s command error : Arguments required".format(args[0])); }
        args.truncArg;
        rm(env, args[0]);
        break;
      default:
        help();
        break;
    }
  } else {
    help();
  }
}
