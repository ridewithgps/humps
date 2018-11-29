#!/bin/bash
rails_root=$(realpath $(dirname $0))
uni_path="$rails_root/config"
echo "scriptdir: $rails_root"

cd $rails_root
bundle exec unicorn -Dc $uni_path/unicorn.rb -E production
