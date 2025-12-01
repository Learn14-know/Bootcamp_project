# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /app

# copy solution and project
COPY *.sln .  # only if solution exists
COPY MyApi/ ./MyApi/

WORKDIR /app/MyApi

# restore & publish
RUN dotnet restore
RUN dotnet publish -c Release -o /out

# Stage 2: Run
FROM mcr.microsoft.com/dotnet/aspnet:7.0
WORKDIR /app
COPY --from=build /out .

EXPOSE 80
ENTRYPOINT ["dotnet", "MyApi.dll"]
