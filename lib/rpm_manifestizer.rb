class RpmManifestizer

  attr_accessor :dry_run

  def initialize settings
    @settings = settings
  
    @cut_off_exceptions = [ "qt4-x11" ]
    @source_rpms = Hash.new
  end

  def create_manifest rpm_name, name
    filename =  "#{@settings.manifest_dir}/#{name}.manifest" 
    File.open( filename, "w") do |f2|
      source_rpm = `rpm -q --queryformat '%{SOURCERPM}' #{rpm_name}`
      @source_rpms[source_rpm] = Array.new

      raw = `rpm -q --queryformat '%{DESCRIPTION}' #{rpm_name}`
      parse_authors = false
      description = ""
      authors = Array.new
      raw.each_line do |line3|
        if line3 =~ /^Authors:/
          parse_authors = true
          next
        end
        if parse_authors
          if line3 =~ /^---/
            next
          end
          authors.push "\"#{line3.strip}\""
        else
          description += line3.chomp + "\\n"
        end
      end
      description.gsub! /"/, "\\\""
      description.strip!

      qf = '  "version": "%{VERSION}",\n'
      qf += '  "summary": "%{SUMMARY}",\n'
      qf += '  "homepage": "%{URL}",\n'
      qf += '  "license": "%{LICENSE}",\n'
      header = `rpm -q --queryformat '#{qf}' #{rpm_name}`

      f2.puts '{';
      f2.puts '  "schema_version": 1,'
      f2.puts "  \"name\": \"#{name}\","
      f2.puts header
      f2.puts "  \"description\": \"#{description}\","
      f2.puts '  "authors": [' + authors.join(",") + '],'
      f2.puts '  "maturity": "stable",'
      f2.puts '  "packages": {'
      f2.puts '    "openSUSE": {'
      f2.puts '      "11.4": {'
      f2.puts "        \"package_name\": \"#{rpm_name}\","
      f2.puts '        "repository": {'
      f2.puts '          "url": "http://download.opensuse.org/distribution/11.4/repo/oss/",'
      f2.puts '          "name": "openSUSE-11.4-Oss"'
      f2.puts '        },'
      f2.puts "        \"source_rpm\": \"#{source_rpm}\""
      f2.puts '      }'
      f2.puts '    }'
      f2.puts '  }'
      f2.puts '}'
    end
  end

  def requires_qt? rpm_name
    IO.popen "rpm -q --requires #{rpm_name}" do |f2|
      while line2 = f2.gets do
        if line2 =~ /Qt/
          return true
        end
      end
    end
    false
  end

  def is_library? rpm_name
    rpm_name =~ /^lib/
  end

  def is_32bit? rpm_name
    rpm_name =~ /\-32bit/
  end

  def cut_off_number_suffix name
    if @cut_off_exceptions.include? name
      return name
    end

    i = name.length - 1
    while i > 0
      if name[i].chr !~ /[\-_0-9]/
        break
      end
      i -= 1
    end
    if i > 0
      return name[0..i]
    end
    name
  end

  def process_all_rpms
    IO.popen "rpmqpack" do |f|
      while line = f.gets do
        rpm_name = line.chomp
        if rpm_name
          next unless requires_qt? rpm_name
          next unless is_library? rpm_name
          next if is_32bit? rpm_name

          if rpm_name =~ /^lib(.*)/
            name = $1
          else
            name = rpm_name
          end

          name = cut_off_number_suffix name

          puts "Found #{name} (#{rpm_name})"

          if !dry_run
            create_manifest rpm_name, name
          end
        end
      end
    end
  end

  def show_source_rpms
    sources = Hash.new
    IO.popen "rpmqpack" do |f|
      while line = f.gets do
        rpm_name = line.chomp
        source_rpm = `rpm -q --queryformat '%{SOURCERPM}' #{rpm_name}`
        sources[rpm_name] = source_rpm
      end
    end

    @source_rpms.keys.sort.each do |source_rpm|
      puts source_rpm
      sources.keys.sort.each do |rpm|
        if sources[rpm] == source_rpm
          puts "  #{rpm}"
        end
      end
    end
  end

end
