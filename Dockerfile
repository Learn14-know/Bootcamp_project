# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /app

# copy csproj and restore
COPY *.sln .
COPY MyApi/*.csproj ./MyApi/
RUN dotnet restore

# copy everything else
COPY MyApi/. ./MyApi/
WORKDIR /app/MyApi
RUN dotnet publish -c Release -o /out

# Stage 2: Run
FROM mcr.microsoft.com/dotnet/aspnet:7.0
WORKDIR /app
COPY --from=build /out .

EXPOSE 80

ENTRYPOINT ["dotnet", "MyApi.dll"]

