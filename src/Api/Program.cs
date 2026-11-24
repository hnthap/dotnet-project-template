using Microsoft.AspNetCore.HttpLogging;
using Microsoft.AspNetCore.HttpOverrides;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddProblemDetails();
builder.Services.AddHealthChecks();
builder.Services.AddValidation();

builder.Logging.AddJsonConsole(o =>
{
    o.IncludeScopes = true;
    o.UseUtcTimestamp = true;
    o.TimestampFormat = "yyyy-MM-dd'T'HH:mm:ss.fffffff'Z'";
});
builder.Services.AddHttpLogging(
    (o) =>
    {
        o.LoggingFields =
            HttpLoggingFields.RequestMethod
            | HttpLoggingFields.RequestPath
            | HttpLoggingFields.ResponseStatusCode
            | HttpLoggingFields.Duration;
        o.CombineLogs = true;
    }
);
builder.Services.AddOpenApi();

// X-Forwarded-* is trusted only from loopback by default; a proxy elsewhere
// needs its network in ForwardedHeaders:KnownNetworks (CIDR, e.g. 10.0.0.0/8)
builder.Services.Configure<ForwardedHeadersOptions>(o =>
{
    o.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
    var networks = builder
        .Configuration.GetSection("ForwardedHeaders:KnownNetworks")
        .Get<string[]>();
    foreach (var network in networks ?? [])
    {
        o.KnownIPNetworks.Add(System.Net.IPNetwork.Parse(network));
    }
});

var app = builder.Build();

app.UseForwardedHeaders();
app.UseHttpLogging();
app.UseExceptionHandler();
app.UseStatusCodePages();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}
app.MapHealthChecks("/healthz");
app.MapGet("/", () => "Hello World!");

app.Run();
