const http = require("http");

const PORT = process.env.PORT || 3000;
const API_KEY = process.env.OMDB_API_KEY || "";

const CATEGORY_MAP = {
  action: { label: "Accion", query: "action" },
  horror: { label: "Terror", query: "horror" },
  other: { label: "Drama", query: "drama" },
};

const CURRENT_IMDB_IDS = [
  "tt15398776",
  "tt15239678",
  "tt1517268",
  "tt1745960",
  "tt10366206",
  "tt10872600",
  "tt1877830",
  "tt6791350",
  "tt1630029",
  "tt0816692",
  "tt1375666",
  "tt0468569",
];

const POSTER_PLACEHOLDER =
  "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='160' height='240'><rect width='100%25' height='100%25' fill='%230f172a'/><text x='50%25' y='50%25' fill='%2394a3b8' font-size='14' font-family='sans-serif' dominant-baseline='middle' text-anchor='middle'>Sin poster</text></svg>";

function normalizePosterUrl(url) {
  if (!url || url === "N/A") {
    return POSTER_PLACEHOLDER;
  }
  return url.replace(/^http:/, "https:");
}

function pageTemplate(title, subtitle, movies, error) {
  const items = movies
    .map(
      (m) =>
        `<li class="card">
          <a class="card-link" href="/movie/${m.imdbID}">
            <img src="${normalizePosterUrl(m.Poster)}" alt="${m.Title}" onerror="this.src='${POSTER_PLACEHOLDER}'" />
            <div>
              <h3>${m.Title}</h3>
              <p>${m.Year}</p>
              <p class="type">${m.Type}</p>
            </div>
          </a>
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
      .card { background: #1e293b; border-radius: 12px; padding: 12px; }
      .card-link { display: flex; gap: 12px; color: inherit; text-decoration: none; }
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

function detailTemplate(movie, error) {
  const errorBlock = error ? `<div class="error">${error}</div>` : "";
  const poster = movie ? normalizePosterUrl(movie.Poster) : POSTER_PLACEHOLDER;

  return `<!doctype html>
<html lang="es">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>${movie ? movie.Title : "Detalle"}</title>
    <style>
      body { font-family: ui-sans-serif, system-ui; background: #0f172a; color: #e2e8f0; margin: 0; }
      header { padding: 24px; background: #111827; }
      h1 { margin: 0 0 8px; font-size: 28px; }
      .sub { color: #94a3b8; }
      nav { display: flex; gap: 12px; padding: 16px 24px; background: #0b1220; }
      a.btn { color: #0f172a; background: #38bdf8; padding: 10px 14px; border-radius: 8px; text-decoration: none; font-weight: 600; }
      main { padding: 24px; display: grid; gap: 16px; grid-template-columns: 200px 1fr; }
      img { width: 200px; height: 300px; object-fit: cover; border-radius: 12px; background: #0f172a; }
      .meta { color: #94a3b8; margin-top: 6px; }
      .error { grid-column: 1 / -1; background: #7f1d1d; padding: 12px; border-radius: 8px; }
      .plot { line-height: 1.6; }
    </style>
  </head>
  <body>
    <header>
      <h1>${movie ? movie.Title : "Detalle"}</h1>
      <div class="sub">${movie ? `${movie.Year} · ${movie.Genre || ""}` : ""}</div>
    </header>
    <nav>
      <a class="btn" href="/">Volver</a>
    </nav>
    <main>
      ${errorBlock}
      <img src="${poster}" alt="${movie ? movie.Title : "Poster"}" onerror="this.src='${POSTER_PLACEHOLDER}'" />
      <div>
        <div class="meta">${movie ? movie.Runtime || "" : ""}</div>
        <div class="meta">${movie ? movie.Director || "" : ""}</div>
        <div class="meta">${movie ? movie.Actors || "" : ""}</div>
        <p class="plot">${movie ? movie.Plot || "Sin descripcion." : ""}</p>
      </div>
    </main>
  </body>
</html>`;
}

async function fetchMovies(query, year, pages = 1) {
  if (!API_KEY) {
    return { error: "OMDB_API_KEY no configurada.", movies: [] };
  }

  try {
    const results = [];
    for (let page = 1; page <= pages; page += 1) {
      const url = new URL("https://www.omdbapi.com/");
      url.searchParams.set("apikey", API_KEY);
      url.searchParams.set("s", query);
      url.searchParams.set("type", "movie");
      url.searchParams.set("page", String(page));
      if (year) {
        url.searchParams.set("y", year);
      }

      const response = await fetch(url.toString());
      const data = await response.json();
      if (data.Response === "True" && Array.isArray(data.Search)) {
        results.push(...data.Search);
      }
    }

    const withPosters = results.filter(
      (movie) => movie.Poster && movie.Poster !== "N/A",
    );
    if (withPosters.length === 0) {
      return { error: "No hay resultados con poster.", movies: [] };
    }
    return { error: "", movies: withPosters };
  } catch (err) {
    return { error: "Error consultando OMDb.", movies: [] };
  }
}

async function fetchByIds(ids) {
  if (!API_KEY) {
    return { error: "OMDB_API_KEY no configurada.", movies: [] };
  }

  try {
    const results = await Promise.all(
      ids.map(async (id) => {
        const url = new URL("https://www.omdbapi.com/");
        url.searchParams.set("apikey", API_KEY);
        url.searchParams.set("i", id);
        const response = await fetch(url.toString());
        const data = await response.json();
        return data.Response === "True" ? data : null;
      }),
    );

    const movies = results.filter(
      (movie) => movie && movie.Poster && movie.Poster !== "N/A",
    );
    if (movies.length === 0) {
      return { error: "No hay resultados con poster.", movies: [] };
    }
    return { error: "", movies };
  } catch (err) {
    return { error: "Error consultando OMDb.", movies: [] };
  }
}

async function fetchMovieDetail(id) {
  if (!API_KEY) {
    return { error: "OMDB_API_KEY no configurada.", movie: null };
  }

  try {
    const url = new URL("https://www.omdbapi.com/");
    url.searchParams.set("apikey", API_KEY);
    url.searchParams.set("i", id);
    url.searchParams.set("plot", "full");
    const response = await fetch(url.toString());
    const data = await response.json();
    if (data.Response !== "True") {
      return { error: data.Error || "No hay resultados.", movie: null };
    }
    return { error: "", movie: data };
  } catch (err) {
    return { error: "Error consultando OMDb.", movie: null };
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

  if (path.startsWith("/movie/")) {
    const id = path.split("/")[2] || "";
    const { error, movie } = await fetchMovieDetail(id);
    const html = detailTemplate(movie, error);
    res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
    res.end(html);
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

  let error = "";
  let movies = [];

  if (path === "/") {
    ({ error, movies } = await fetchByIds(CURRENT_IMDB_IDS));
  } else {
    ({ error, movies } = await fetchMovies(query, "", 1));
  }
  const html = pageTemplate(title, subtitle, movies, error);

  res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
  res.end(html);
});

server.listen(PORT, () => {
  console.log(`cine app listening on ${PORT}`);
});
