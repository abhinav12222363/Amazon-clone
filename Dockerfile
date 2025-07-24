# Use the official Nginx image to serve static files
FROM nginx:alpine

# Remove the default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy your static website to nginx's public folder
COPY . /usr/share/nginx/html

# Expose port 80 to access the app
EXPOSE 80

# Start Nginx when container launches
CMD ["nginx", "-g", "daemon off;"]
