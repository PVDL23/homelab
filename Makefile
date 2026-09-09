init-proxmox:
	cd terraform/proxmox && terraform init

plan-proxmox:
	cd terraform/proxmox && terraform plan --out=planout

apply-proxmox:
	cd terraform/proxmox && terraform apply planout



# ansible 
install-docker:
	cd ansible && ansible-playbook playbooks/install-docker.yml