module ApiVersions
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)
      if request.path.include?('/api/')
        if !env['HTTP_ACCEPT']
          env['HTTP_ACCEPT'] = "application/vnd.#{ApiVersions::VersionCheck.vendor_string}"
        elsif !env['HTTP_ACCEPT'].include?("vnd.#{ApiVersions::VersionCheck.vendor_string}")
          env['HTTP_ACCEPT'] += ",application/vnd.#{ApiVersions::VersionCheck.vendor_string}"
        end

        if env['CONTENT_TYPE']
          env['HTTP_ACCEPT'] += "+#{env['CONTENT_TYPE'].split('/').last}"
        else
          env['HTTP_ACCEPT'] += "+json"
        end

      else
        return @app.call(env) unless env['HTTP_ACCEPT']
      end

      accepts = env['HTTP_ACCEPT'].split(',')
      offset = 0
      accepts.dup.each_with_index do |accept, i|
        accept.strip!
        match = /\Aapplication\/vnd\.#{ApiVersions::VersionCheck.vendor_string}\s*\+\s*(?<format>\w+)\s*/.match(accept)
        if match
          if env['CONTENT_TYPE']
            prefix = env['CONTENT_TYPE'].split('/').first
          else
            prefix = 'application'
          end
          accepts.insert i + offset, "#{prefix}/#{match[:format]}"
          offset += 1
        end
      end

      env['HTTP_ACCEPT'] = accepts.join(',')
      @app.call(env)
    end
  end
end
