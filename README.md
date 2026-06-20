# 🔍 Recon Automation

Proyek ini adalah script Bash untuk otomatisasi subdomain enumeration dan live host probing menggunakan **subfinder**, **httpx**, dan **anew**. Dirancang untuk keperluan bug bounty dan penetration testing.

---

## 📁 Struktur Proyek
recon-automation-john/
├── input/
│ └── domains.txt # Daftar domain target
├── output/
│ ├── all-subdomains.txt # Semua subdomain unik
│ └── live.txt # Live hosts dengan status & title
├── scripts/
│ └── recon-auto.sh # Script utama
├── logs/
│ ├── progress.log # Log progress
│ └── errors.log # Log error
└── README.md


---

## ⚙️ Setup Environment

### 1. Install Dependencies
```bash
sudo apt update && sudo apt install -y git golang-go

wget https://go.dev/dl/go1.24.3.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.24.3.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.bashrc
source ~/.bashrc

# pdtm
go install -v github.com/projectdiscovery/pdtm/cmd/pdtm@latest

# subfinder & httpx
pdtm -install subfinder,httpx

# anew
go install -v github.com/tomnomnom/anew@latest

subfinder -version
httpx -version
anew -h
