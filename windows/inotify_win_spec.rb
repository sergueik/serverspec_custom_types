# https://stackoverflow.com/questions/3517460/is-there-anything-like-inotify-on-windows
# origin:
# https://github.com/thekid/inotify-win/blob/master/src/Runner.cs
add-type -typeDefinition @'

using System;
using System.Threading;
using System.IO;
using System.Collections.Generic;
using System.Text.RegularExpressions;

namespace De.Thekid.INotify
{
    // List of possible changes
    public enum Change
    {
        CREATE, MODIFY, DELETE, MOVED_FROM, MOVED_TO
    }

    /// Main class
    public class Runner
    {
        // Mappings
        protected static Dictionary<WatcherChangeTypes, Change> Changes = new Dictionary<WatcherChangeTypes, Change>();

        private List<Thread> _threads = new List<Thread>();
        private bool _stopMonitoring = false;
        private ManualResetEventSlim _stopMonitoringEvent;
        private object _notificationReactionLock = new object();
        private Arguments _args = null;

        static Runner()
        {
            Changes[WatcherChangeTypes.Created]= Change.CREATE;
            Changes[WatcherChangeTypes.Changed]= Change.MODIFY;
            Changes[WatcherChangeTypes.Deleted]= Change.DELETE;
        }

        public Runner(Arguments args)
        {
            _args = args;
        }

        /// Callback for errors in watcher
        protected void OnWatcherError(object source, ErrorEventArgs e)
        {
            Console.Error.WriteLine("*** {0}", e.GetException());
        }

        private void OnWatcherNotification(object sender, FileSystemEventArgs e)
        {
            var w = (FileSystemWatcher)sender;
            HandleNotification((FileSystemWatcher)sender, e, () => Output(Console.Out, _args.Format, w, Changes[e.ChangeType], e.Name));
        }
        
        private void OnRenameNotification(object sender, RenamedEventArgs e)
        {
            var w = (FileSystemWatcher)sender;
            HandleNotification(w, e, () =>
            {
                Output(Console.Out, _args.Format, w, Change.MOVED_FROM, e.OldName);
                Output(Console.Out, _args.Format, w, Change.MOVED_TO, e.Name);
            });
        }
        
        private void HandleNotification(FileSystemWatcher sender, FileSystemEventArgs e, Action outputAction)
        {
            // Lock so we don't output more than one change if we were only supposed to watch for one.
            // And to serialize access to the console
            lock (_notificationReactionLock)
            {
                // if only looking for one change and another thread beat us to it, return
                if (!_args.Monitor && _stopMonitoring)
                {
                    return;
                }
        
                if (null != _args.Exclude && _args.Exclude.IsMatch(e.FullPath))
                {
                    return;
                }
        
                outputAction();
        
                // If only looking for one change, signal to stop
                if (!_args.Monitor)
                {
                    _stopMonitoring = true;
                    _stopMonitoringEvent.Set();
                }
            }
        }

        /// Output method
        protected void Output(TextWriter writer, string[] tokens, FileSystemWatcher source, Change type, string name)
        {
            foreach (var token in tokens)
            {
                var path = Path.Combine(source.Path, name);
                switch (token[0])
                {
                    case 'e':
                        writer.Write(type);
                        if (Directory.Exists(path))
                        {
                            writer.Write(",ISDIR");
                        }
                        break;
                    case 'f': writer.Write(Path.GetFileName(path)); break;
                    case 'w': writer.Write(Path.Combine(source.Path, Path.GetDirectoryName(path))); break;
                    case 'T': writer.Write(DateTime.Now); break;
                    default: writer.Write(token); break;
                }
            }
            writer.WriteLine();
        }

        public void Processor(object data)
        {
            string path = (string)data;

            string fileName = "*.*";

            if (File.Exists(path))
            {
                fileName = Path.GetFileName(path);
                path = Path.GetDirectoryName(path);
            }

            using (var w = new FileSystemWatcher {
                Path = path,
                IncludeSubdirectories = _args.Recursive,
                Filter = fileName
            }) {
                w.Error += new ErrorEventHandler(OnWatcherError);

                // Parse "events" argument
                WatcherChangeTypes changes = 0;
                if (_args.Events.Contains("create"))
                {
                    changes |= WatcherChangeTypes.Created;
                    w.Created += new FileSystemEventHandler(OnWatcherNotification);
                }
                if (_args.Events.Contains("modify"))
                {
                    changes |= WatcherChangeTypes.Changed;
                    w.Changed += new FileSystemEventHandler(OnWatcherNotification);
                }
                if (_args.Events.Contains("delete"))
                {
                    changes |= WatcherChangeTypes.Deleted;
                    w.Deleted += new FileSystemEventHandler(OnWatcherNotification);
                }
                if (_args.Events.Contains("move"))
                {
                    changes |= WatcherChangeTypes.Renamed;
                    w.Renamed += new RenamedEventHandler(OnRenameNotification);
                }

                // Main loop
                if (!_args.Quiet)
                {
                    Console.Error.WriteLine(
                        "===> {0} {1}{2}{4} for {3}",
                        _args.Monitor ? "Monitoring" : "Watching",
                        path,
                        _args.Recursive ? " -r" : "",
                        String.Join(", ", _args.Events),
                        fileName
                    );
                }
                w.EnableRaisingEvents = true;
                _stopMonitoringEvent.Wait();
            }
        }

        public void StdInOpen()
        {
            while (Console.ReadLine() != null);
            _stopMonitoring = true;
            _stopMonitoringEvent.Set();
        }

        /// Entry point
        public int Run()
        {
            using (_stopMonitoringEvent = new ManualResetEventSlim(initialState: false))
            {
                foreach (var path in _args.Paths)
                {
                    var t = new Thread(new ParameterizedThreadStart(Processor));
                    t.Start(path);
                    _threads.Add(t);
                }

                var stdInOpen = new Thread(new ThreadStart(StdInOpen));
                stdInOpen.IsBackground = true;
                stdInOpen.Start();

                _stopMonitoringEvent.Wait();

                foreach (var thread in _threads)
                {
                    if (thread.IsAlive) thread.Abort();
                    thread.Join();
                }
                return 0;
            }
        }

        /// Entry point method
        public static int Main(string[] args)
        {
            var p = new ArgumentParser();

            // Show usage if no args or standard "help" args are given
            if (0 == args.Length || args[0].Equals("-?") || args[0].Equals("--help"))
            {
                p.PrintUsage("inotifywait", Console.Error);
                return 1;
            }

            // Run!
            return new Runner(p.Parse(args)).Run();
        }
    }
    
      /// See also <a href="http://linux.die.net/man/1/inotifywait">inotifywait(1) - Linux man page</a>
    public class ArgumentParser
    {

        /// Helper method for parser
        protected string Value(string[] args, int i, string name)
        {
            if (i > args.Length)
            {
                throw new ArgumentException("Argument " + name + " requires a value");
            }
            return args[i];
        }

        /// Tokenizes "printf" format string into an array of strings
        protected string[] TokenizeFormat(string arg)
        {
            var result = new List<string>();
            var tokens = arg.Split(new char[]{ '%' });
            foreach (var token in tokens)
            {
                if (token.Length == 0) continue;

                if ("efwT".IndexOf(token[0]) != -1)
                {
                    result.Add(token[0].ToString());
                    if (token.Length > 1)
                    {
                        result.Add(token.Substring(1));
                    }
                }
                else
                {
                    result.Add(token);
                }
            }
            return result.ToArray();
        }

        private void ParseArgument(string option, string[] args, ref int i, Arguments result)
        {
            if ("--recursive" == option || "-r" == option)
            {
                result.Recursive = true;
            }
            else if ("--monitor" == option || "-m" == option)
            {
                result.Monitor = true;
            }
            else if ("--quiet" == option || "-q" == option)
            {
                result.Quiet = true;
            }
            else if ("--event" == option || "-e" == option)
            {
                result.AddEvents(Value(args, ++i, "event").Split(','));
            }
            else if ("--format" == option)
            {
                result.Format = TokenizeFormat(Value(args, ++i, "format"));
            }
            else if ("--exclude" == option)
            {
                result.Exclude = new Regex(Value(args, ++i, "exclude"));
            }
            else if ("--excludei" == option)
            {
                result.Exclude = new Regex(Value(args, ++i, "exclude"), RegexOptions.IgnoreCase);
            }
            else if (option.StartsWith("--event="))
            {
                result.AddEvents(option.Split(new Char[]{'='}, 2)[1].Split(','));
            }
            else if (option.StartsWith("--format="))
            {
                result.Format = TokenizeFormat(option.Split(new Char[]{'='}, 2)[1]);
            }
            else if (option.StartsWith("--exclude="))
            {
                result.Exclude = new Regex(option.Split(new Char[]{'='}, 2)[1]);
            }
            else if (option.StartsWith("--excludei="))
            {
                result.Exclude = new Regex(option.Split(new Char[]{'='}, 2)[1], RegexOptions.IgnoreCase);
            }
            else if (Directory.Exists(option) || File.Exists(option))
            {
                result.Paths.Add(System.IO.Path.GetFullPath(option));
            }
        }

        /// Creates a new argument parser and parses the arguments
        public Arguments Parse(string[] args)
        {
            var result = new Arguments();
            for (var i = 0; i < args.Length; i++)
            {
                if (!args[i].StartsWith("--") && args[i].StartsWith("-") && args[i].Length > 2)
                {
                    string options = args[i];
                    for (var j = 1; j < options.Length; j++)
                    {
                        ParseArgument("-" + options.Substring(j, 1), args, ref i, result);
                    }
                }
                else
                {
                    ParseArgument(args[i], args, ref i, result);
                }
            }
            return result;
        }

        /// Usage
        public void PrintUsage(string name, TextWriter writer)
        {
            writer.WriteLine("Usage: " + name + " [options] path [...]");
            writer.WriteLine();
            writer.WriteLine("Options:");
            writer.WriteLine("-r/--recursive:  Recursively watch all files and subdirectories inside path");
            writer.WriteLine("-m/--monitor:    Keep running until killed (e.g. via Ctrl+C)");
            writer.WriteLine("-q/--quiet:      Do not output information about actions");
            writer.WriteLine("-e/--event list: Which events (create, modify, delete, move) to watch, comma-separated. Default: all");
            writer.WriteLine("--format format: Format string for output.");
            writer.WriteLine("--exclude:       Do not process any events whose filename matches the specified regex");
            writer.WriteLine("--excludei:      Ditto, case-insensitive");
            writer.WriteLine();
            writer.WriteLine("Formats:");
            writer.WriteLine("%e             : Event name");
            writer.WriteLine("%f             : File name");
            writer.WriteLine("%w             : Path name");
            writer.WriteLine("%T             : Current date and time");
        }
    }
}

'@
