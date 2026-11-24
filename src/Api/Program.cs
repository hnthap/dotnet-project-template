var builder = WebApplication.CreateBuilder(args);

builder.Services.AddProblemDetails();
builder.Services.AddHealthChecks();
builder.Services.AddValidation();
builder.Services.AddHttpLogging(
    (o) =>
    {
        o.LoggingFields =
            Microsoft.AspNetCore.HttpLogging.HttpLoggingFields.RequestMethod
            | Microsoft.AspNetCore.HttpLogging.HttpLoggingFields.RequestPath
            | Microsoft.AspNetCore.HttpLogging.HttpLoggingFields.ResponseStatusCode
            | Microsoft.AspNetCore.HttpLogging.HttpLoggingFields.Duration;
        o.CombineLogs = true;
    }
);
builder.Services.AddOpenApi();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}
app.UseHttpLogging();
app.UseExceptionHandler();
app.UseStatusCodePages();

app.MapHealthChecks("/healthz");
app.MapGet("/", () => "Hello World!");

app.Run();
