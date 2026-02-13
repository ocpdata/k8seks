const http = require("http");

const PORT = process.env.PORT || 3000;
const API_KEY = process.env.OMDB_API_KEY || "";

const CATEGORY_MAP = {
  action: { label: "Accion", query: "action" },
  horror: { label: "Terror", query: "horror" },
  other: { label: "Drama", query: "drama" },
};

function pageTemplate(title, subtitle, movies, error) {
  const items = movies
    .map(
      (m) =>
        `<li class="card">
          <img src="${m.Poster !== "N/A" ? m.Poster : ""}" alt="${m.Title}" />
          <div>
            <h3>${m.Title}</h3>
            <p>${m.Year}</p>
            <p class="type">${m.Type}</p>
          </div>
        </li>`,
    )
    .join("");

  const errorBlock = error ? `<div class="error">${error}</div>` : "";

  return `<!doctype html>
<html lang="es">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>${title}</title>
    <style>
      body { font-family: ui-sans-serif, system-ui; background: #0f172a; color: #e2e8f0; margin: 0; }
      header { padding: 24px; background: #111827; }
      h1 { margin: 0 0 8px; font-size: 28px; }
      .sub { color: #94a3b8; }
      nav { display: flex; gap: 12px; padding: 16px 24px; background: #0b1220; }
      a.btn { color: #0f172a; background: #38bdf8; padding: 10px 14px; border-radius: 8px; text-decoration: none; font-weight: 600; }
      main { padding: 24px; }
      ul { list-style: none; padding: 0; display: grid; grid-template-columns: repeat(auto-fill, minmax(240px, 1fr)); gap: 16px; }
      .card { background: #1e293b; border-radius: 12px; padding: 12px; display: flex; gap: 12px; }
      .card img { width: 80px; height: 120px; object-fit: cover; border-radius: 8px; background: #0f172a; }
      .type { color: #94a3b8; font-size: 12px; text-transform: uppercase; letter-spacing: 0.08em; }
      .error { background: #7f1d1d; padding: 12px; border-radius: 8px; margin-bottom: 16px; }
    </style>
  </head>
  <body>
    <header>
      <h1>${title}</h1>
      <div class="sub">${subtitle}</div>
    </header>
    <nav>
      <a class="btn" href="/">Actuales</a>
      <a class="btn" href="/category/action">Accion</a>
      <a class="btn" href="/category/horror">Terror</a>
      <a class="btn" href="/category/other">Otra</a>
    </nav>
    <main>
      ${errorBlock}
      <ul>${items}</ul>
    </main>
  </body>
</html>`;
}

async function fetchMovies(query, year) {
  if (!API_KEY) {
    return { error: "OMDB_API_KEY no configurada.", movies: [] };
  }

  const url = new URL("http://www.omdbapi.com/");
  url.searchParams.set("apikey", API_KEY);
  url.searchParams.set("s", query);
  url.searchParams.set("type", "movie");
  if (year) {
    url.searchParams.set("y", year);
  }

  try {
    const response = await fetch(url.toString());
    const data = await response.json();
    if (data.Response !== "True") {
      return { error: data.Error || "No hay resultados.", movies: [] };
    }
    return { error: "", movies: data.Search || [] };
  } catch (err) {
    return { error: "Error consultando OMDb.", movies: [] };
  }
}

const server = http.createServer(async (req, res) => {
  const requestUrl = new URL(req.url, `http://${req.headers.host}`);
  const path = requestUrl.pathname;

  if (path === "/healthz") {
    res.writeHead(200, { "Content-Type": "text/plain" });
    res.end("ok");
    return;
  }

  let title = "Peliculas actuales";
  let subtitle = "Seleccion actual de peliculas";
  let query = "movie";
  const year = new Date().getFullYear().toString();

  if (path.startsWith("/category/")) {
    const category = path.split("/")[2] || "";
    const config = CATEGORY_MAP[category];
    if (config) {
      title = `Peliculas de ${config.label}`;
      subtitle = `Categoria: ${config.label}`;
      query = config.query;
    } else {
      title = "Categoria desconocida";
      subtitle = "Selecciona otra categoria";
      query = "movie";
    }
  }

  const { error, movies } = await fetchMovies(query, path === "/" ? year : "");
  const html = pageTemplate(title, subtitle, movies, error);

  res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
  res.end(html);
});

server.listen(PORT, () => {
  console.log(`cine app listening on ${PORT}`);
});
