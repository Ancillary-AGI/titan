use axum::{extract::State, routing::{get, post}, Json, Router};
use serde::{Deserialize, Serialize};
use std::{net::SocketAddr, sync::Arc};
use tracing::{info, error};
use chromiumoxide::browser::{Browser, BrowserConfig};
use chromiumoxide::cdp::browser_protocol::page::NavigateParams;
use chromiumoxide::Page;

#[derive(Clone)]
struct AppState {
    browser: Arc<Browser>,
    page: Arc<Page>,
}

#[derive(Serialize)]
struct Health { status: &'static str }

#[derive(Deserialize)]
struct NavigateReq { url: String }

#[derive(Deserialize)]
struct ClickReq { selector: String }

#[derive(Deserialize)]
struct ExtractReq { selector: String, attribute: Option<String> }

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .init();

    let (browser, mut handler) = Browser::launch(
        BrowserConfig::builder()
            .with_head()
            .build()?
    ).await?;

    tokio::spawn(async move { while let Some(evt) = handler.next().await { if let Err(e) = evt { error!(?e, "browser event error"); } } });

    let page = browser.new_page("about:blank").await?;
    let state = AppState { browser: Arc::new(browser), page: Arc::new(page) };

    let app = Router::new()
        .route("/health", get(health))
        .route("/navigate", post(navigate))
        .route("/click", post(click))
        .route("/content", get(content))
        .route("/extract", post(extract))
        .with_state(state);

    let addr: SocketAddr = "127.0.0.1:9224".parse()?;
    info!(%addr, "titan_agent listening");
    axum::Server::bind(&addr).serve(app.into_make_service()).await?;
    Ok(())
}

async fn health() -> Json<Health> { Json(Health { status: "ok" }) }

async fn navigate(State(state): State<AppState>, Json(req): Json<NavigateReq>) -> Json<serde_json::Value> {
    let _ = state.page.navigate(NavigateParams::builder().url(req.url.clone()).build()).await;
    Json(serde_json::json!({"ok": true}))
}

async fn click(State(state): State<AppState>, Json(req): Json<ClickReq>) -> Json<serde_json::Value> {
    let js = format!("(() => {{ const el = document.querySelector('{}'); if (el) {{ el.click(); return 'ok'; }} return 'not_found'; }})()", req.selector.replace("'", "\\'"));
    let _ = state.page.evaluate(js).await;
    Json(serde_json::json!({"ok": true}))
}

async fn content(State(state): State<AppState>) -> Json<serde_json::Value> {
    let res = state.page.content().await.unwrap_or_default();
    Json(serde_json::json!({"html": res}))
}

async fn extract(State(state): State<AppState>, Json(req): Json<ExtractReq>) -> Json<serde_json::Value> {
    let attr = req.attribute.unwrap_or_else(|| "textContent".to_string());
    let js = format!("(() => {{ const el = document.querySelector('{}'); if (!el) return ''; const v = el['{}']; return (v || '').toString(); }})()", req.selector.replace("'", "\\'"), attr);
    let val = state.page.evaluate(js).await.ok().and_then(|v| v.into_value()).unwrap_or(serde_json::Value::Null);
    Json(serde_json::json!({"value": val}))
}
