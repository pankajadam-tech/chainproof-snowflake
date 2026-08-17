"""Pure Part 9 evidence retrieval, trust-boundary, and citation logic.

This module has no Streamlit or Snowflake imports so it can be tested locally.
"""
from __future__ import annotations

import json
import re
from typing import Any, Iterable

SEARCH_SERVICE = "CHAINPROOF.APP.CHAINPROOF_EVIDENCE_SEARCH"
UNTRUSTED_DOCUMENT_IDS = {"DOC-UNTRUSTED-001"}
PROMPT_INJECTION_PATTERNS = (
    re.compile(r"\bignore\b.*\b(approved|contract|instruction|policy)\b", re.I),
    re.compile(r"\b(auto|automatically)\s*approve\b", re.I),
    re.compile(r"\bhide\b.*\b(result|evidence|date)\b", re.I),
    re.compile(r"\b(delete|update|insert|merge|drop|alter)\b.*\b(governance|metric)\b", re.I),
)
STOPWORDS = {
    "a", "an", "and", "are", "as", "at", "be", "by", "for", "from",
    "how", "in", "is", "it", "of", "on", "or", "the", "this", "to",
    "was", "what", "when", "where", "which", "why", "with",
}


def clean_evidence_query(value: str) -> str:
    query = " ".join(str(value or "").split()).strip()
    if not query:
        raise ValueError("Evidence question cannot be empty")
    if len(query) > 1000:
        raise ValueError("Evidence question is too long")
    return query


def contains_prompt_injection(text: str) -> bool:
    normalized = " ".join(str(text or "").split())
    return any(pattern.search(normalized) for pattern in PROMPT_INJECTION_PATTERNS)


def _tokens(value: str) -> set[str]:
    return {
        token
        for token in re.findall(r"[a-z0-9][a-z0-9_-]+", str(value or "").lower())
        if token not in STOPWORDS and len(token) > 1
    }


def _record_value(record: dict[str, Any], key: str, default: Any = "") -> Any:
    if key in record:
        return record[key]
    lower = key.lower()
    for existing, value in record.items():
        if str(existing).lower() == lower:
            return value
    return default


def is_trusted_result(record: dict[str, Any], allowed_document_ids: Iterable[str]) -> bool:
    allowed = {str(value) for value in allowed_document_ids}
    document_id = str(_record_value(record, "DOCUMENT_ID", ""))
    chunk_text = str(_record_value(record, "CHUNK_TEXT", ""))
    if not document_id or document_id not in allowed:
        return False
    if document_id in UNTRUSTED_DOCUMENT_IDS:
        return False
    if contains_prompt_injection(chunk_text):
        return False
    trusted = _record_value(record, "IS_TRUSTED", True)
    if isinstance(trusted, str):
        trusted = trusted.upper() in {"TRUE", "1", "YES"}
    return bool(trusted)


def citation_label(record: dict[str, Any]) -> str:
    explicit = str(_record_value(record, "CITATION_LABEL", "")).strip()
    if explicit:
        return explicit
    document_id = str(_record_value(record, "DOCUMENT_ID", "UNKNOWN"))
    section = str(_record_value(record, "SECTION_TITLE", "Evidence"))
    return f"[{document_id} §{section}]"


def deterministic_rank_chunks(
    records: Iterable[dict[str, Any]],
    query: str,
    allowed_document_ids: Iterable[str],
    limit: int = 5,
) -> list[dict[str, Any]]:
    """Rank trusted applicable evidence without a model or external service."""
    cleaned = clean_evidence_query(query)
    query_tokens = _tokens(cleaned)
    ranked: list[dict[str, Any]] = []
    for record in records:
        item = dict(record)
        if not is_trusted_result(item, allowed_document_ids):
            continue
        title = str(_record_value(item, "DOCUMENT_TITLE", ""))
        section = str(_record_value(item, "SECTION_TITLE", ""))
        chunk = str(_record_value(item, "CHUNK_TEXT", ""))
        keywords = str(_record_value(item, "KEYWORDS", ""))
        topic = str(_record_value(item, "EVIDENCE_TOPIC", ""))
        score = 0
        score += 4 * len(query_tokens & _tokens(title))
        score += 4 * len(query_tokens & _tokens(section))
        score += 3 * len(query_tokens & _tokens(keywords))
        score += 2 * len(query_tokens & _tokens(topic))
        score += len(query_tokens & _tokens(chunk))
        if not query_tokens:
            score = 1
        item["RELEVANCE_SCORE"] = score
        item["CITATION_LABEL"] = citation_label(item)
        item["RETRIEVAL_MODE"] = "DETERMINISTIC_TRUSTED_FALLBACK"
        ranked.append(item)
    ranked.sort(
        key=lambda item: (
            -int(item.get("RELEVANCE_SCORE", 0)),
            str(_record_value(item, "DOCUMENT_ID", "")),
            int(_record_value(item, "CHUNK_ORDER", 0) or 0),
        )
    )
    if ranked and ranked[0].get("RELEVANCE_SCORE", 0) == 0:
        # A zero-overlap question still receives a small, deterministic applicable
        # evidence set rather than an invented answer.
        for item in ranked:
            item["RELEVANCE_SCORE"] = 0
    return ranked[: max(1, min(int(limit), 10))]


def build_search_preview_sql(
    query: str,
    allowed_document_ids: Iterable[str],
    limit: int = 5,
    service_name: str = SEARCH_SERVICE,
) -> str:
    cleaned = clean_evidence_query(query)
    document_ids = sorted({str(value) for value in allowed_document_ids if value})
    if not document_ids:
        raise ValueError("At least one applicable evidence document is required")
    filters = [{"@eq": {"DOCUMENT_ID": value}} for value in document_ids]
    payload: dict[str, Any] = {
        "query": cleaned,
        "columns": [
            "CHUNK_ID",
            "DOCUMENT_ID",
            "DOCUMENT_TITLE",
            "DOCUMENT_TYPE",
            "SECTION_TITLE",
            "CHUNK_TEXT",
            "CITATION_LABEL",
            "EVIDENCE_TOPIC",
            "SUPPORTS_METRIC_COMPONENT",
        ],
        "limit": max(1, min(int(limit), 10)),
        "filter": filters[0] if len(filters) == 1 else {"@or": filters},
    }
    payload_literal = json.dumps(payload, separators=(",", ":")).replace("'", "''")
    service_literal = str(service_name).replace("'", "''")
    return (
        "SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW("
        f"'{service_literal}', '{payload_literal}') AS SEARCH_RESPONSE"
    )


def parse_search_preview(
    raw_value: Any,
    allowed_document_ids: Iterable[str],
) -> list[dict[str, Any]]:
    if raw_value is None:
        return []
    if isinstance(raw_value, str):
        parsed = json.loads(raw_value)
    elif isinstance(raw_value, dict):
        parsed = raw_value
    else:
        try:
            parsed = json.loads(str(raw_value))
        except json.JSONDecodeError as exc:
            raise ValueError("Cortex Search returned an unreadable response") from exc
    results = parsed.get("results", []) if isinstance(parsed, dict) else []
    trusted: list[dict[str, Any]] = []
    for result in results:
        if not isinstance(result, dict) or not is_trusted_result(result, allowed_document_ids):
            continue
        item = {str(key).upper(): value for key, value in result.items()}
        item["CITATION_LABEL"] = citation_label(item)
        item["RETRIEVAL_MODE"] = "CORTEX_SEARCH"
        trusted.append(item)
    return trusted


def evidence_answer(results: Iterable[dict[str, Any]], question: str) -> dict[str, Any]:
    items = list(results)
    if not items:
        return {
            "summary": "No applicable trusted evidence was found. ChainProof will not invent support for the decision.",
            "citations": [],
            "result_count": 0,
        }
    citations = [citation_label(item) for item in items]
    topics = []
    for item in items:
        topic = str(_record_value(item, "EVIDENCE_TOPIC", "")).replace("_", " ").title()
        if topic and topic not in topics:
            topics.append(topic)
    summary = (
        f"ChainProof found {len(items)} applicable trusted evidence passage(s) for "
        f"‘{clean_evidence_query(question)}’. The strongest support covers "
        f"{', '.join(topics[:3]) or 'the governed metric contract'}. "
        "The evidence can explain or recommend; it cannot approve or modify a metric."
    )
    return {"summary": summary, "citations": citations, "result_count": len(items)}
