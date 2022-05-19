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

def load_data(fname)
  File.open(fname, 'rb') do |f|
    data = Marshal.load(f)
    for d in data
      d[1].force_encoding("UTF-8")
    end
    return data
  end
end

def extract_all_scripts
  # msgwindow=Kernel.pbCreateMessageWindow
  # Kernel.pbMessageDisplay(msgwindow,_INTL("Por favor, espera.\\wtnp[0]"))

  p 'Extrayendo scripts...'

  FileUtils.mkdir_p('scripts') unless File.directory?('scripts')

  File.open('scripts/export.txt', 'w') do |info|
    info.puts("scripts\n")
    begin
      scripts = load_data('Data/Scripts.rxdata')
      scripts ||= []
    rescue StandardError => e
      puts 'No se ha podido cargar Scripts.rxdata'
      scripts = []
    end

    scripts.each do |script|
      if script[1].include?("\\") || script[1].include?("/") || script[1].include?(":") || script[1].include?("*") || script[1].include?("?") || script[1].include?("\"") || script[1].include?("<") || script[1].include?(">") || script[1].include?("|")
        p "El script #{script[1]} tiene un nombre inválido, corrígelo antes de volver a intentar exportar los scripts."
        gets
        exit
      end
    end

    scripts.each do |script|
      next if script[1].match(/=+/)
      File.open("scripts/#{script[1]}.rb", 'wb') do |file|
        file.write(Zlib::Inflate.inflate(script[2]))
      end
      info.puts("#{script[0]},#{script[1]}\n")
    end

    info.puts("#-------------------\n")

    info.puts("constants\n")

    begin
      scripts = load_data('Data/Constants.rxdata')
      scripts ||= []
    rescue StandardError
      puts 'No se ha podido cargar Constants.rxdata'
      scripts = []
    end

    scripts.each do |script|
      File.open("scripts/#{script[1]}.rb", 'wb') do |file|
        file.write(Zlib::Inflate.inflate(script[2]))
      end
      info.puts("#{script[0]},#{script[1]}\n")
    end
  end
  # Kernel.pbMessageDisplay(msgwindow, "Extracción finalizada")
  # Kernel.pbDisposeMessageWindow(msgwindow)
  p 'Extracción finalizada.'
end

extract_all_scripts