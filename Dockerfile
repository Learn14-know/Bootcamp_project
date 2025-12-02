# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy everything into container
COPY . .

# Restore dependencies and publish
RUN dotnet restore MyApi.csproj
RUN dotnet publish MyApi.csproj -c Release -o /app/publish

# Stage 2: Runtime
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app

# Copy published app
COPY --from=build /app/publish .

# Expose port 80 (AKS expects container ports to be exposed)
EXPOSE 80

# Run the application
ENTRYPOINT ["dotnet", "MyApi.dll"]
