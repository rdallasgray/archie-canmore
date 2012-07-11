begin
  require 'jasmine'
  load 'jasmine/tasks/jasmine.rake'
rescue LoadError
  task :jasmine do
    abort "Jasmine is not available. In order to run jasmine, you must: (sudo) gem install jasmine"
  end
end

src_dir = "src/"
build_dir = "lib/"
min_dir = "../public/javascripts/"
xcode_src_dir = "xcode/"
xcode_target_dir = "/Users/robertdallasgray/Documents/Code/ARchiOS/ARchiOS/"
xcode_js_files = ["xcode/jquery.min.js", "../public/javascripts/architect-min.js"]
xcode_html_header = "#{xcode_src_dir}architect-header.html"
xcode_html_footer = "#{xcode_src_dir}architect-footer.html"
xcode_html_o = "#{xcode_src_dir}architect.html"
xcode_files = ["#{xcode_src_dir}architect.html", "../public/stylesheets/main.css"]

src_files =[
  "architect",
  "main"
]

tasks_run = []

files = src_files.map {|f| src_dir + f}
build_name = "architect-build.js"
min_name = "architect-min.js"

task :clean => [:compile] do
  return if tasks_run.include? :clean
  sh "rm #{build_dir + build_name}"
  tasks_run.push :clean
end

task :compile do
  return if tasks_run.include? :compile
  sh "coffee --join #{build_dir + build_name} --compile #{files.join ' '}"
  tasks_run.push :compile
end

task :min => [:compile] do
  return if tasks_run.include? :min
  sh "uglifyjs -o #{min_dir + min_name} #{build_dir + build_name}"
  tasks_run.push :min
end

task :release => [:compile, :min, :clean]

task :xcode => [:release] do
  sh "cat #{xcode_html_header} #{xcode_js_files.join ' '} #{xcode_html_footer} > #{xcode_html_o}"
  sh "cp #{xcode_files.join ' '} #{xcode_target_dir}"
end
