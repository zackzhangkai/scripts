#!/bin/sh

set -e 
set -o 
set -x 

yum -y install bash-completion

source <(kubectl completion bash)

egrep -w "source <(kubectl completion bash)" /root/.bashrc ||  echo "source <(kubectl completion bash)" >> ~/.bashrc # 在您的 bash shell 中永久的添加自动补全

alias k=kubectl
egrep -w "alias k=kubectl" /root/.bashrc || echo "alias k=kubectl" >> /root/.bashrc

complete -F __start_kubectl k
egrep "complete -F __start_kubectl k" /root/.bashrc || echo "complete -F __start_kubectl k" >> /root/.bashrc

# install krew
(
  set -x; cd "$(mktemp -d)" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew.{tar.gz,yaml}" &&
  tar zxvf krew.tar.gz &&
  KREW=./krew-"$(uname | tr '[:upper:]' '[:lower:]')_amd64" &&
  "$KREW" install --manifest=krew.yaml --archive=krew.tar.gz &&
  "$KREW" update
)

kubectl krew install ns

# install zsh
if [ -n "$1" ]; then
    if [ "$1" == "zsh" ]; then
	yum -y zsh
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
	cd root/.oh-my-zsh/plugins/
	git clone  https://github.com/zsh-users/zsh-autosuggestions.git
	sed -i 's/^ZSH_THEME=.*/ZSH_THEME="maran"/' /root/.zshrc
	source <(kubectl completion zsh)  # 在 zsh 中设置当前 shell 的自动补全
	erep -w "source <(kubectl completion zsh)" /root/.zshrc  || echo "source <(kubectl completion zsh)" >> /root/.zshrc
    else
        echo "The option should be "zsh""
    fi
