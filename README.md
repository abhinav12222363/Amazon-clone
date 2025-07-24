# 🛒 Amazon Clone

A front-end static clone of the Amazon website built using HTML, CSS, and JavaScript. This project replicates the look and basic feel of Amazon's homepage.

## 🚀 Live Demo

🌐 [Click here to view the project](https://abhinav12222363.github.io/Amazon-clone/)

---

## 📁 Project Structure

Amazon-clone/
├── images/ # Image assets used in the UI
├── index.html # Main HTML page
├── style.css # All styles for the project
├── script.js # (Optional) JavaScript for interactivity
└── README.md # Project documentation


---

## 🧰 Technologies Used

- ✅ HTML5
- ✅ CSS3
- ✅ JavaScript (vanilla)

---

## 🐳 Docker Support

A `Dockerfile` is included to containerize the static site:

```dockerfile
# Dockerfile

FROM nginx:alpine
COPY . /usr/share/nginx/html
EXPOSE 80

# Build Docker image
docker build -t abhinaprakash783/amazon-project-devops .

# Run locally
docker run -d -p 8080:80 abhinaprakash783/amazon-project-devops

 Jenkins Integration
CI/CD pipeline using Jenkins:

Clones the repository

Builds the Docker image

Pushes to Docker Hub

Optionally deploys to a container
