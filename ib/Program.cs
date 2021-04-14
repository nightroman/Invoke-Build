using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;

class IBOptions
{
    public List<string> Arguments { get; }
    public bool ShowMainHelp { get; }
    public bool ShowHelp { get; }
    public string HelpTopic { get; }
    public bool UsePwsh { get; }

    public IBOptions(string[] args)
    {
        Arguments = new List<string>(args);
        while (Arguments.Count > 0)
        {
            switch (Arguments[0])
            {
                case "-?":
                case "/?":
                    ShowMainHelp = true;
                    Arguments.RemoveAt(0);
                    break;
                case "-h":
                case "--help":
                    ShowHelp = true;
                    Arguments.RemoveAt(0);
                    if (Arguments.Count > 0)
                        HelpTopic = Arguments[0];
                    return;
                case "--pwsh":
                    UsePwsh = true;
                    Arguments.RemoveAt(0);
                    break;
                default:
                    return;
            }
        }
    }
}

class Program
{
    static int Main(string[] args)
    {
        const string HelpText = @"The following commands and options are supported:

- Show this help
  ib -h|--help

- Show command help
  ib -h|--help task|exec|assert|...

- Show Invoke-Build help
  ib -?
  ib /?

- Call Invoke-Build with arguments
  ib [--pwsh] [arguments]

    --pwsh
      On Windows tells to run by pwsh (the default is powershell).
      On other platforms pwsh is used and required in any case.
";
        try
        {
            var options = new IBOptions(args);
            if (options.ShowHelp && options.HelpTopic == null)
            {
                Console.WriteLine(HelpText);
                return 0;
            }

            var app = options.UsePwsh || Environment.OSVersion.Platform != PlatformID.Win32NT ? "pwsh" : "powershell";

            var root = Path.GetDirectoryName(typeof(Program).Assembly.Location);
            var ib = Path.Combine(root, "../../../InvokeBuild/Invoke-Build.ps1");
            ib = Path.GetFullPath(ib);
            ib = EscapeArgument(ib);

            var info = new ProcessStartInfo(app);
            var list = info.ArgumentList;
            list.Add("-NoProfile");
            list.Add("-ExecutionPolicy");
            list.Add("Bypass");
            list.Add("-Command");
            if (options.ShowHelp)
            {
                list.Add(".");
                list.Add(ib);
                list.Add(";");
                list.Add("Get-Help");
                list.Add("-Full");
                list.Add(options.HelpTopic);
            }
            else if (options.ShowMainHelp)
            {
                list.Add("Get-Help");
                list.Add("-Full");
                list.Add(ib);
            }
            else
            {
                list.Add("&");
                list.Add(ib);
                foreach (var arg in options.Arguments)
                    list.Add(EscapeArgument(arg));
            }
            var process = Process.Start(info);
            process.WaitForExit();
            return process.ExitCode;
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine(ex.Message);
            return -1;
        }
    }

    static string EscapeArgument(string value)
    {
        if (value.Contains(' ') || value.Contains('\''))
            return "'" + value.Replace("'", "''") + "'";
        else
            return value;
    }
}
