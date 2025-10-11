#1st Stage to build the application

# Set Base image to build the application
FROM node:18-alpine3.17 AS builder

# Set working directory
WORKDIR /src/app

# Copy package-lock.json to the working directory
COPY package*.json ./

# It’s faster and ensures reproducible builds compare to manual npm install good for dev & testing stages 
RUN npm ci 

# Copy application source code to the working directory
COPY . .

#2nd Stage to run the application
FROM node:18-alpine3.17 AS runner

# Set working directory
WORKDIR /src/app

# Copy package files from the builder stage
COPY --from=builder /src/app/package*.json ./

# Install ONLY production dependencies. This creates a smaller node_modules folder.
# `--omit=dev` is the modern equivalent of `--production` for `npm ci`.
RUN npm ci --omit=dev

# Copy only the necessary application code from the builder stage
COPY --from=builder /src/app .

# Runtime environment variables go here
ENV MONGO_URI=uriPlaceholder
ENV MONGO_USERNAME=usernamePlaceholder
ENV MONGO_PASSWORD=passwordPlaceholder

# Application binds to port 3000
EXPOSE 3000

# Run app as a non-root user following best security practices
RUN addgroup --system app && adduser --system --ingroup app app

# Switch to the non-root user
USER app

# Start the application
CMD ["npm", "start"]