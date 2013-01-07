def sync_extension(all_extensions, extname, mime, expires, compress)
  count = 0
  exclude_list = all_extensions.find_all{|x| x != extname}.map{|x| "--exclude '*.#{x}'"}.join(" ")

  if compress
    extra = "--add-header \"Content-Encoding: gzip\""
    Dir["build2/**/*." + extname].each do |fpath|
      `gzip -9 #{fpath} && mv #{fpath}.gz #{fpath}`
    end    
  else
    extra = ""
  end

  if mime
    mimesetting = "-m '#{mime}'"
  else
    mimesetting = ""
  end

  puts
  puts "===========> SYNC: .#{extname} files to sync with mime #{mime || 'unknown'}, expires=#{expires}"
  puts

  sh("s3cmd --config=./.s3cfg sync build2/ s3://www.bionicspirit.com --acl-public --add-header \"Cache-Control: public, max-age=#{expires}\" --check-md5 #{mimesetting} #{extra} --include *.#{extname} #{exclude_list}")
end

task :sync do
  sh("bundle exec middleman build -c && rm -rf build2 && mkdir build2 && rsync -arv build/ build2/")
  all_extensions = Dir["build2/**/*"].find_all{|x| ! File.directory?(x)}.map{|x| File.extname(x)[1..10]}.uniq

  begin
    all_extensions.each do |extname|
      if extname =~ /html?/
        sync_extension(all_extensions, extname, "text/html", 86400, true)
      elsif extname == "xml"
        sync_extension(all_extensions, extname, "application/xml", 86400, true)
      elsif extname == "txt"
        sync_extension(all_extensions, extname, "text/plain", 86400, true)
      elsif extname == "css"
        sync_extension(all_extensions, extname, "text/css", 22896000, true)
      elsif extname == "js"
        sync_extension(all_extensions, extname, "text/javascript", 22896000, true)
      elsif ["png", "gif", "jpg", "jpeg"].member?(extname)
        sync_extension(all_extensions, extname, nil, 22896000, false)
      elsif extname == "ico"
        sync_extension(all_extensions, extname, "image/vnd.microsoft.icon", 22896000, false)
      else
        puts "===========> NOTE: NOT SYNCRONIZING *.#{extname} FILES!!!"
      end
    end

    puts
    puts "===========> DELETE MISSING FILES"
    puts

    sh("s3cmd --config=./.s3cfg sync build2/ s3://www.bionicspirit.com --delete-removed --no-check-md5")
  ensure
    `rm -rf build2`
  end
end

task :rebuildclassic do
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

    sh("s3cmd --config=./.s3cfg put #{fpath} s3://www.bionicspirit.com/#{s3path} --acl-public --add-header \"Cache-Control: public, max-age=#{expires}\" #{extra} #{mimesetting}")
  end

  sh("rm -rf build2/")
end

