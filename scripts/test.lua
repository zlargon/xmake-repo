-- imports
import("core.base.option")

-- the options
local options =
{
    {'v', "verbose",    "k",  nil, "Enable verbose information."   }
,   {'D', "diagnosis",  "k",  nil, "Enable diagnosis information." }
,   {nil, "packages",   "vs", nil, "The package list."             }
}

-- the main entry
function main(...)

    -- parse arguments
    local argv = option.parse({...}, options, "Test all the given or changed packages.")

    -- get packages
    local packages = argv.packages or {}
    if #packages == 0 then
        local files = os.iorun("git diff --name-only HEAD^")
        for _, file in ipairs(files:split('\n'), string.trim) do
            if file:find("packages", 1, true) and path.filename(file) == "xmake.lua" then
                local package = path.filename(path.directory(file))
                table.insert(packages, package)
            end
        end
    end
    if #packages == 0 then
        table.insert(packages, "tbox dev")
    end
    local repodir = os.curdir()
    local workdir = path.join(os.tmpdir(), "xmake-repo")
    print(packages)
    os.setenv("XMAKE_STATS", "false")
    os.tryrm(workdir)
    os.mkdir(workdir)
    os.cd(workdir)
    os.exec("xmake create test")
    os.cd("test")
    print(os.curdir())
    os.exec("xmake repo --add local-repo %s", repodir)
    os.exec("xmake repo -l")
    local require_argv = {"require", "-f", "-y"}
    if argv.verbose then
        table.insert(require_argv, "-v")
    end
    if argv.diagnosis then
        table.insert(require_argv, "-D")
    end
    table.join2(require_argv, packages)
    os.execv("xmake", require_argv)
end
