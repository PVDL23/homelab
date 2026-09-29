help:
	@echo "Terraform:"
	@echo "  make init-<env>    # Initialize (env: proxmox, docker)"
	@echo "  make plan-<env>    # Plan and save to planout"
	@echo "  make apply-<env>   # Apply saved plan"
	@echo ""
	@echo "Ansible:"
	@echo "  make install-docker # Run install-docker playbook"

init-%:
	cd terraform/$* && terraform init

plan-%:
	cd terraform/$* && terraform plan --out=planout

apply-%:
	cd terraform/$* && terraform apply planout

# ansible
install-docker:
	cd ansible && ansible-playbook playbooks/install-docker.yml

install-vault:
	cd ansible && ansible-playbook playbooks/install-vault.yml