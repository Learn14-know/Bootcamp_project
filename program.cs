var builder = WebApplication.CreateBuilder(args);

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

app.MapGet("/", () => "Welcome to the Bootcamp .NET API!");
app.MapGet("/health", () => new { status = "healthy", timestamp = DateTime.UtcNow });

app.UseSwagger();
app.UseSwaggerUI();

app.Run();
