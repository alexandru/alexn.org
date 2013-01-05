task :rebuild do
  sh("bundle exec middleman build -c")
  sh("rm -rf build2 && cp -rf build build2")

  Dir["build2/**/*"].each do |fpath|
    next if File.directory?(fpath)
    extension = File.extname(fpath)[1..-1].downcase
    s3path = fpath.sub(/^[\/]?build2\//, "")
    mimesetting = ""

    if extension =~ /s?css/
      mimesetting = "-m text/css"
      compress = true
    elsif extension == "js"
      mimesetting = "-m text/javascript"
      compress = true
    elsif extension =~ /html?/
      mimesetting = "-m text/html"
      compress = true
    elsif fpath =~ /atom.xml/
      mimesetting = "-m application/atom+xml"
      compress = true
    elsif extension == "xml"
      mimesetting = "-m application/xml"
      compress = true
    elsif extension == "txt"
      mimesetting = "-m text/plain"
      compress = true
    elsif extension == "woff"
      mimesetting = '-m application/x-font-woff'
      compress = false
    elsif ["png", "gif", "jpg", "jpeg"].member?(extension)
      compress = false
    elsif extension == "ico"
      mimesetting = "-m image/vnd.microsoft.icon"
      compress = false
    else
      $stderr.puts "ERROR: unknown extension '#{extension}' for #{fpath}"
      exit(1)
    end

    if compress 
      sh("gzip -9 #{fpath} && mv #{fpath}.gz #{fpath}") 
      extra = "--add-header \"Content-Encoding: gzip\""
    else
      extra = ""
    end

    if extension =~ /html?/
      expires = 86400
    else
      expires = 22896000
    end

    sh("s3cmd --config=.s3cfg put #{fpath} s3://www.bionicspirit.com/#{s3path} --acl-public --add-header \"Cache-Control: public, max-age=#{expires}\" #{extra} #{mimesetting}")
  end

  sh("rm -rf build2/")
end

