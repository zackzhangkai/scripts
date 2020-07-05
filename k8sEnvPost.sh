#!/bin/sh

set -e 
set -o 
set -x 

yum -y install bash-completion

# install krew
ls /root/.krew || \
(
  set -x; cd "$(mktemp -d)" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew.{tar.gz,yaml}" &&
  tar zxvf krew.tar.gz &&
  KREW=./krew-"$(uname | tr '[:upper:]' '[:lower:]')_amd64" &&
  "$KREW" install --manifest=krew.yaml --archive=krew.tar.gz &&
  "$KREW" update
)
export PATH="${PATH}:/root/.krew/bin"
egrep "/root/.krew/bin" /root/.bashrc || echo "export PATH="${PATH}:/root/.krew/bin"" >> /root/.bashrc

kubectl krew list | grep ns || kubectl krew install ns

# install zsh
if [ -n "$1" ]; then
    if [ "$1" == "zsh" ]; then
	if [ ! -f /root/.zshrc ]; then
	    yum -y install zsh
	    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
	fi
        ls /root/.oh-my-zsh/plugins/zsh-autosuggestions &> /dev/null || ( cd /root/.oh-my-zsh/plugins/ && git clone https://github.com/zsh-users/zsh-autosuggestions.git )
	sed -i 's/^ZSH_THEME=.*/ZSH_THEME="maran"/' /root/.zshrc
	sed -i 's/^plugins=.*/plugins=(git zsh-autosuggestions)/' /root/.zshrc
	egrep -w "source <(kubectl completion zsh)" /root/.zshrc  || echo "source <(kubectl completion zsh)" >> /root/.zshrc
    else
        echo "The option should be "zsh""
    fi
  echo $SHELL | grep zsh || chsh -s /bin/zsh
  echo "Do \"source /root/.zshrc\""

else
  egrep 'kubectl completion bash' /root/.bashrc ||  echo "source <(kubectl completion bash)" >> ~/.bashrc # 在您的 bash shell 中永久的添加自动补全
  egrep -w "alias k=kubectl" /root/.bashrc || echo "alias k=kubectl" >> /root/.bashrc
  egrep "complete -F __start_kubectl k" /root/.bashrc || echo "complete -F __start_kubectl k" >> /root/.bashrc
  echo $SHELL | grep bash || chsh -s /bin/bash
  echo "Do \"source /root/.bashrc\""

fi



