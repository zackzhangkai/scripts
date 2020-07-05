#!/bin/sh
#
#  curl https://raw.githubusercontent.com/zackzhangkai/scripts/master/k8sInstallPost.sh | bash
# OR: 
#  curl https://raw.githubusercontent.com/zackzhangkai/scripts/master/k8sInstallPost.sh > k8sInstallPost.sh && echo yes | sh k8sInstallPost.sh zsh
#

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

kubectl krew list | grep ns || kubectl krew install ns

# install zsh
if [ -n "$1" ]; then
    if [ "$1" == "zsh" ]; then
        yum -y install zsh
	ls /root/.oh-my-zsh &> /dev/null || sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
        ls /root/.oh-my-zsh/plugins/zsh-autosuggestions &> /dev/null || ( cd /root/.oh-my-zsh/plugins/ && git clone https://github.com/zsh-users/zsh-autosuggestions.git )
	sed -i 's/^ZSH_THEME=.*/ZSH_THEME="maran"/' /root/.zshrc
	sed -i 's/^plugins=.*/plugins=(git zsh-autosuggestions)/' /root/.zshrc
	egrep -w "kubectl completion zsh" /root/.zshrc  || echo "source <(kubectl completion zsh)" >> /root/.zshrc
        egrep -w "alias k=kubectl" /root/.zshrc || echo "alias k=kubectl" >> /root/.zshrc
        egrep "complete -F __start_kubectl k" /root/.zshrc || echo "complete -F __start_kubectl k" >> /root/.zshrc
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



