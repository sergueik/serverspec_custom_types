require 'spec_helper'


# http://www.cyberforum.ru/shell/thread2526703.html
# somewhat scholastic ...

context 'silent rm command' do
  files = [
  ]
  describe command(<<-EOF
    pushd "$ARHIVE_DIR" > /dev/null
    (IFS=$'\\n'
    FILES=( $(ls -1 "$BACKUP_LABEL"{.tgz,.sht,_prev.lnk} 2>/dev/null) )
    declare -p FILES
    if [ ${#FILES[@]} -gt 0 ]; then rm -i ${FILES[@]}; fi )
    popd > /dev/null
    EOF
  ) do
    its(:stderr) { should be_empty }
  end
end