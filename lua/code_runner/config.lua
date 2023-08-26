local default_launchers = {
  { pattern = 'javascript', name = 'run javascript program', cmd = 'node' },
  {
    pattern = 'java',
    name = 'run java program',
    cmd = 'cd $dir && javac $fileName && java $fileNameWithoutExt',
  },
  {
    pattern = 'c',
    name = 'run c program',
    cmd = 'cd $dir && gcc $fileName -o $fileNameWithoutExt && $dir$fileNameWithoutExt',
  },
  {
    pattern = 'cpp',
    name = 'run cpp program',
    cmd = 'cd $dir && g++ $fileName -o $fileNameWithoutExt && $dir$fileNameWithoutExt',
  },
  {
    pattern = 'objective-c',
    name = 'run objective-c program',
    cmd = 'cd $dir && gcc -framework Cocoa $fileName -o $fileNameWithoutExt && $dir$fileNameWithoutExt',
  },
  { pattern = 'php', name = 'run php program', cmd = 'php' },
  {
    pattern = 'python',
    name = 'run python program',
    cmd = 'cd $dir && python3 -u $fileName',
  },
  { pattern = 'perl', name = 'run perl program', cmd = 'perl' },
  { pattern = 'perl6', name = 'run perl6 program', cmd = 'perl6' },
  { pattern = 'ruby', name = 'run ruby program', cmd = 'ruby' },
  { pattern = 'go', name = 'run go program', cmd = 'go run . ' },
  { pattern = 'lua', name = 'run lua program', cmd = 'lua' },
  { pattern = 'groovy', name = 'run groovy program', cmd = 'groovy' },
  {
    pattern = 'powershell',
    name = 'run powershell program',
    cmd = 'powershell -ExecutionPolicy ByPass -File',
  },
  { pattern = 'bat', name = 'run bat program', cmd = 'cmd /c' },
  { pattern = 'shellscript', name = 'run shellscript program', cmd = 'bash' },
  { pattern = 'fsharp', name = 'run fsharp program', cmd = 'fsi' },
  { pattern = 'csharp', name = 'run csharp program', cmd = 'scriptcs' },
  {
    pattern = 'vbscript',
    name = 'run vbscript program',
    cmd = 'cscript //Nologo',
  },
  { pattern = 'typescript', name = 'run typescript program', cmd = 'ts-node' },
  { pattern = 'coffeescript', name = 'run coffeescript program', cmd = 'coffee' },
  { pattern = 'scala', name = 'run scala program', cmd = 'scala' },
  { pattern = 'swift', name = 'run swift program', cmd = 'swift' },
  { pattern = 'julia', name = 'run julia program', cmd = 'julia' },
  { pattern = 'crystal', name = 'run crystal program', cmd = 'crystal' },
  { pattern = 'ocaml', name = 'run ocaml program', cmd = 'ocaml' },
  { pattern = 'r', name = 'run r program', cmd = 'Rscript' },
  { pattern = 'applescript', name = 'run applescript program', cmd = 'osascript' },
  { pattern = 'clojure', name = 'run clojure program', cmd = 'lein exec' },
  {
    pattern = 'haxe',
    name = 'run haxe program',
    cmd = 'haxe --cwd $dirWithoutTrailingSlash --run $fileNameWithoutExt',
  },
  {
    pattern = 'rust',
    name = 'run rust program',
    cmd = 'cd $dir && rustc $fileName && $dir$fileNameWithoutExt',
  },
  { pattern = 'racket', name = 'run racket program', cmd = 'racket' },
  {
    pattern = 'scheme',
    name = 'run scheme program',
    cmd = 'csi -script',
  },
  { pattern = 'ahk', name = 'run ahk program', cmd = 'autohotkey' },
  { pattern = 'autoit', name = 'run autoit program', cmd = 'autoit3' },
  { pattern = 'dart', name = 'run dart program', cmd = 'dart' },
  {
    pattern = 'pascal',
    name = 'run pascal program',
    cmd = 'cd $dir && fpc $fileName && $dir$fileNameWithoutExt',
  },
  {
    pattern = 'd',
    name = 'run d program',
    cmd = 'cd $dir && dmd $fileName && $dir$fileNameWithoutExt',
  },
  { pattern = 'haskell', name = 'run haskell program', cmd = 'runhaskell' },
  {
    pattern = 'nim',
    name = 'run nim program',
    cmd = 'nim compile --verbosity:0 --hints:off --run',
  },
  {
    pattern = 'lisp',
    name = 'run lisp program',
    cmd = 'sbcl --script',
  },
  { pattern = 'kit', name = 'run kit program', cmd = 'kitc --run' },
  { pattern = 'v', name = 'run v program', cmd = 'v run' },
  {
    pattern = 'sass',
    name = 'run sass program',
    cmd = 'sass --style expanded',
  },
  {
    pattern = 'scss',
    name = 'run scss program',
    cmd = 'scss --style expanded',
  },
  {
    pattern = 'less',
    name = 'run less program',
    cmd = 'cd $dir && lessc $fileName $fileNameWithoutExt.css',
  },
  {
    pattern = 'FortranFreeForm',
    name = 'run FortranFreeForm program',
    cmd = 'cd $dir && gfortran $fileName -o $fileNameWithoutExt && $dir$fileNameWithoutExt',
  },
  {
    pattern = 'fortran-modern',
    name = 'run fortran-modern program',
    cmd = 'cd $dir && gfortran $fileName -o $fileNameWithoutExt && $dir$fileNameWithoutExt',
  },
  {
    pattern = 'fortran_fixed-form',
    name = 'run fortran_fixed-form program',
    cmd = 'cd $dir && gfortran $fileName -o $fileNameWithoutExt && $dir$fileNameWithoutExt',
  },
  {
    pattern = 'fortran',
    name = 'run fortran program',
    cmd = 'cd $dir && gfortran $fileName -o $fileNameWithoutExt && $dir$fileNameWithoutExt',
  },
}
local default_config = {}

local M = {}

M.setup = function(opts)
  opts = opts or {}
  local user_launchers = opts.launchers or {}
  opts.launchers = vim.list_extend(user_launchers, default_launchers)

  local new_conf = vim.tbl_deep_extend('force', default_config, opts)
  for k, v in pairs(new_conf) do
    M[k] = v
  end
end

return M
