require 'spec_helper'

context 'erb tests' do

  title = 'Jaws'
  file = '/tmp/a.' + Process.pid.to_s + '.rb'
  context 'hash' do
    describe command(<<-EOF
      echo '@movie = {"title" => "#{title}"}' > #{file}
      echo '<%= @movie["title"] %>' | erb -r #{file} -
      rm #{file}
    EOF
    ) do
      its(:stderr) { should be_empty }
      its(:stdout) { should contain title }
    end
  end
  context 'object' do
    describe command(<<-EOF
      printf "class Movie\n attr_accessor :title\n end\n@movie = Movie.new; @movie.title = '#{title}'" > #{file}
      echo '<%= @movie.title %>' | erb -r #{file} -
      rm #{file}
    EOF
    ) do
      its(:stderr) { should be_empty }
      its(:stdout) { should contain title }
    end
    describe command(<<-EOF
      printf "class Movie\n attr_accessor :title\ndef initialize(title)\n@title = title\nend\nend\n@movie = Movie.new('#{title}')" > #{file}
      echo '<%= @movie.title %>' | erb -r #{file} -
      rm #{file}
    EOF
    ) do
      its(:stderr) { should be_empty }
      its(:stdout) { should contain title }
    end
  end
end
