# frozen_string_literal: true

require 'zlib'
require 'fileutils'

def pbFindScript(a, name)
    a.each do |i|
      next unless i
      return i if i[1] == name
    end
    nil
end

def pbAddScriptToGivenFile(scripts, script, sectionname, _fname)
  s = pbFindScript(scripts, sectionname)
  if s
    s[2] = Zlib::Deflate.deflate("#{script}\r\n")
  else
    scripts.insert(scripts.size - 1, [rand(100_000_000), sectionname, Zlib::Deflate.deflate("#{script}\r\n")])
  end
  # sleep(0.001)
  scripts
  end

def load_data(fname)
  File.open(fname, 'rb') do |f|
    data = Marshal.load(f)
    for d in data
      d[1].force_encoding("UTF-8")
    end
    return data
  end
  end

def save_data(data, fname)
  File.open(fname, 'wb') do |f|
    Marshal.dump(data, f)
  end
end

def import_all_scripts
  # msgwindow=Kernel.pbCreateMessageWindow
  # Kernel.pbMessageDisplay(msgwindow,_INTL("Por favor, espera.\\wtnp[0]"))

  p 'Importando scripts...'

  if !File.directory?("scripts")
    FileUtils.mkdir_p("scripts")
  end

  datestr = Time.now.strftime("%d_%m_%Y_%H_%M")

  FileUtils.cp("Data/Scripts.rxdata", "Data/Scripts_#{datestr}.rxdata")

  dir_files = Dir['scripts/*.rb']

  scripts = {
    'scripts' => [],
    'constants' => []
  }

  File.open('scripts/export.txt', 'r') do |f|
    content = f.read
    lists = content.split("#-------------------\n")
    lists.each do |files|
      counter = 0
      file_lines = files.split("\n")
      file_lines.each do |file|
        scripts[files.split("\n")[0]].push(file.split(',')) if counter > 0
        counter += 1
      end
    end
  end

  begin
    all_scripts = load_data('Data/Scripts.rxdata')
    all_scripts ||= []
  rescue StandardError
    all_scripts = []
  end

  dir_files.each do |file|
    next if scripts['constants'].flatten.include?(File.basename(file, '.*'))

    File.open(file, 'r') do |f|
      all_scripts = pbAddScriptToGivenFile(all_scripts, f.read, File.basename(file, '.*'), 'Data/Scripts.rxdata')
    end
  end

  # save_data(all_scripts,"Data/Scripts.rxdata")

  to_delete = []

  dir_files_bases = dir_files.map do |f|
    File.basename(f, '.*')
  end

  all_scripts.each do |script|
    if !dir_files_bases.include?(script[1]) && !script[1].match(/=+/)
      p "Going to delete #{script[1]}"
      to_delete.push(script)
    end
  end

  to_delete.each do |script|
    all_scripts.delete(script)
  end

  save_data(all_scripts, 'Data/Scripts.rxdata')

  # Kernel.pbMessageDisplay(msgwindow, "Importación finalizada")
  # Kernel.pbDisposeMessageWindow(msgwindow)

  p 'Importación finalizada.'
  end

import_all_scripts