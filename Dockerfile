#1st Stage to build the application

# Set Base image to build the application
FROM node:18-alpine3.17 AS builder

# Set working directory
WORKDIR /src/app

# Copy package-lock.json to the working directory
COPY package*.json /src/app/

# It’s faster and ensures reproducible builds compare to manual npm install good for dev & testing stages 

RUN npm ci 

#use RUN npm install --production for final production image. Slower to build low reproducibility no dev dependencies.

# note in this project we are not building the application like we usually do with a 'build' step to create a production-ready artifact

# Copy application source code to the working directory
COPY . .

#2nd Stage to run the application
FROM node:18-alpine3.17 AS runner

# Set working directory
WORKDIR /src/app

# Copy built assets from the builder stage
COPY --from=builder /src/app .

# Runtime environment variables go here
ENV MONGO_URI=uriPlaceholder
ENV MONGO_USERNAME=usernamePlaceholder
ENV MONGO_PASSWORD=passwordPlaceholder

# Application environment variable will be passed during runtime as needed : -
#  docker run -p 3000:3000 \
#  -e MONGO_URI="mongodb://..." \
#  -e MONGO_USERNAME="user" \
#  -e MONGO_PASSWORD="pass" \
#  my-app <your app name>

# Application binds to port 3000
EXPOSE 3000

# Run app as a non-root user following best security practices
RUN addgroup --system app && adduser --system --ingroup app app

# Switch to the non-root user
USER app

# Start the application
CMD ["npm", "start"]