#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# Cliente HTTP basado en wininet https://learn.microsoft.com/en-us/windows/win32/api/wininet/
# por: polectron
# Este script es una modificación del script Download & Upload Files with RGSS 
#   adaptado para funcionar como una librería HTTP genérica y no solo para descargar archivos
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# Download & Upload Files with RGSS
# por: berka
# version 2.1 
# rgss 1
# http://www.rpgmakervx-fr.com
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# Gracias a: http://www.66rpg.com por la documentación sobre wininet
# Gracias a: https://mundo-maker.foroactivo.com/t15069-rmxprmvx-bajar-archivos-de-internet por ser la unica copia del script que encuentro online
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

module Net
    W='wininet'
  
    INTERNET_OPEN_TYPE_DIRECT=1
    INTERNET_SERVICE_HTTP=3
    HTTP_QUERY_STATUS_CODE=19
    HTTP_QUERY_RAW_HEADERS_CRLF=22
  
    HTTP_ADDREQ_FLAG_REPLACE=0x80000000
  
    SPC=Win32API.new('kernel32','SetPriorityClass','pi','i').call(-1,128)
    IOA=Win32API.new(W,'InternetOpenA','plppl','l')
    ICA=Win32API.new(W,'InternetConnectA','lplpplll','l')
    HORA=Win32API.new(W,'HttpOpenRequestA','lpppppll','l')
    HARHA=Win32API.new(W,'HttpAddRequestHeadersA','lpll','l')
    HSRA=Win32API.new(W,'HttpSendRequestA','lplpl','i')
    IOU=Win32API.new(W,'InternetOpenUrl','lppllp','l')
    IRF=Win32API.new(W,'InternetReadFile','lpip','l')
    ICH=Win32API.new(W,'InternetCloseHandle','l','l')
    HQIA=Win32API.new(W,'HttpQueryInfoA','llppp','i')
    #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
    module HTTP
  
      GET="GET"
      POST="POST"
  
      module_function
      def request(method, url, params=nil, body=nil, headers=nil)
        url_parts=url.split('/')
        server=url_parts[2]
        path=url_parts[3..url_parts.size].join('/')
        hInternet=IOA.call('', INTERNET_OPEN_TYPE_DIRECT, nil, nil, 0)
        if hInternet!=0
          hConnect=ICA.call(hInternet, server, 80, nil, nil, INTERNET_SERVICE_HTTP, 0, 0)
          if hConnect!=0
            # TODO: add urlencoded params into path
            if not params.nil?
              terms = []
              params.each do |key, value|
                terms.push("#{key}=#{value}")
              end
              path = "#{path}?#{terms.join('&')}"
            end
            hRequest=HORA.call(hConnect, method, path, nil, nil, nil, 0, 0)
            if hRequest!=0
              HARHA.call(hRequest, "User-Agent: RPG Maker XP", -1, HTTP_ADDREQ_FLAG_REPLACE)
              if not headers.nil?
                headers.each do |key, value|
                  HARHA.call(hRequest, "#{key}: #{value}", -1, HTTP_ADDREQ_FLAG_REPLACE)
                end
              end
              # TODO: implement post data for application/x-www-form-urlencoded
              msg = ''
              if not body.nil?
                if body.instance_of? Hash
                  HARHA.call(hRequest, "Content-Type: application/x-www-form-urlencoded", -1, HTTP_ADDREQ_FLAG_REPLACE)
                  terms = []
                  body.each do |key, value|
                    terms.push("#{key}=#{value}")
                  end
                  msg = terms.join("&")
                else
                  HARHA.call(hRequest, "Content-Type: application/text", -1, HTTP_ADDREQ_FLAG_REPLACE)
                  msg = body
                end
              end
              bRequestSent=HSRA.call(hRequest, nil, 0, msg, msg.bytesize)
              if bRequestSent!=0
                content = ''
                h=HQIA.call(hRequest,HTTP_QUERY_STATUS_CODE,k="\0"*1024,[k.size-1].pack('l'),nil)
                status_code = k.delete!("\0").to_i
                h=HQIA.call(hRequest,HTTP_QUERY_RAW_HEADERS_CRLF,k="\0"*1024,[k.size-1].pack('l'),nil)
                raw_headers = k.delete!("\0").split("\r\n")
                headers = {}
                raw_headers.each do |raw_header|
                  key, value = raw_header.split(":")
                  headers[key] = value.strip if not value.nil?
                end
                loop do
                  buf,n=' '*1024,0
                  r=IRF.call(hRequest,buf,1024,o=[n].pack('i!'))
                  n=o.unpack('i!')[0]
                  break if r&&n==0
                  content << buf[0,n]
                end
                return status_code, headers, content
              else
                raise "No se pudo enviar la petición"
              end
              ICH.call(hRequest)
            else
              raise "No se pudo preparar la petición"
            end
            ICH.call(hConnect)
          else
            raise "No se pudo establecer conexión con el servidor"
          end
          ICH.call(hInternet)
        else
          raise "No se pudo abrir una conexión a internet"
        end
      end
       
     def get(url, params=nil, headers=nil)
       return request(GET, url, params, nil, headers)
     end
     
     def post(url, params=nil, body=nil, headers=nil)
      return request(POST, url, params, body, headers)
     end
    end
  end

def pbDownloadToString(url)
  if $joiplay
    return ""
  end
  begin
    code, headers, content = Net::HTTP.get(url)
    data = content
    return data
  rescue
    return ""
  end 
end

def pbDownloadData(url, file=nil)
  if $joiplay
    return ""
  end
  code, headers, content = Net::HTTP.get(url)
  if file.nil?
    return content
  else
    File.open(file, "wb") do |f|
      f.write(content)
    end
    return content
  end
end

def pbPostData(url, postdata, file=nil)
  if $joiplay
    return ""
  end
  code, headers, content = Net::HTTP.post(url, nil, postdata)
  if file.nil?
    return content
  else
    File.open(file, "wb") do |f|
      f.write(content)
    end
    return content
  end
end

def pbDownloadToFile(url, file)
  begin
    pbDownloadData(url, file)
  rescue
  end
end

def pbPostToString(url, postdata)
  begin
    data = pbPostData(url, postdata)
    return data
  rescue
    return ""
  end 
end

def pbPostToFile(url, postdata, file)
  begin
    pbPostData(url, postdata, file)
  rescue
  end
end
