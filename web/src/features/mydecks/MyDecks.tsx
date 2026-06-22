import { useState } from "react";

import type { Card, Deck, Language, PartOfSpeech } from "../../shared/api/types";
import type { CardPayload } from "./api";
import { useDeckCards } from "./useDeckCards";
import { useMyDecks } from "./useMyDecks";

const POS_OPTIONS: PartOfSpeech[] = [
  "noun",
  "verb",
  "adjective",
  "adverb",
  "phrase",
  "other",
];

export function MyDecks({ onStudy }: { onStudy?: (deck: Deck) => void }) {
  const {
    decks,
    languages,
    loading,
    busy,
    error,
    createDeck,
    renameDeck,
    deleteDeck,
  } = useMyDecks();
  const [openDeckId, setOpenDeckId] = useState<number | null>(null);

  if (loading) {
    return (
      <div className="screen screen--center">
        <div className="spinner" />
      </div>
    );
  }

  const openDeck = decks.find((d) => d.id === openDeckId) ?? null;

  return (
    <div className="screen">
      <h1 className="screen__title">Decks</h1>
      {error && <div className="alert">{error}</div>}

      <NewDeckForm languages={languages} busy={busy} onCreate={createDeck} />

      {decks.length === 0 ? (
        <p className="muted" style={{ textAlign: "center", marginTop: 18 }}>
          No decks yet — create your first one.
        </p>
      ) : (
        <div className="deck-list mydeck-list">
          {decks.map((deck) => (
            <DeckRow
              key={deck.id}
              deck={deck}
              languages={languages}
              busy={busy}
              open={deck.id === openDeckId}
              onToggle={() =>
                setOpenDeckId((id) => (id === deck.id ? null : deck.id))
              }
              onRename={renameDeck}
              onDelete={deleteDeck}
              onStudy={onStudy}
            />
          ))}
        </div>
      )}

      {openDeck && <DeckCards key={openDeck.id} deck={openDeck} />}
    </div>
  );
}

function langCode(languages: Language[], id: number) {
  return languages.find((l) => l.id === id)?.code.toUpperCase() ?? "?";
}

function NewDeckForm({
  languages,
  busy,
  onCreate,
}: {
  languages: Language[];
  busy: boolean;
  onCreate: (language: number, name: string) => void | Promise<void>;
}) {
  const [name, setName] = useState("");
  const [language, setLanguage] = useState<number | "">("");

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim() || language === "") return;
    await onCreate(language, name.trim());
    setName("");
  };

  return (
    <form className="card mydeck-form" onSubmit={submit}>
      <div className="mydeck-form__row">
        <input
          className="input"
          placeholder="New deck name"
          value={name}
          onChange={(e) => setName(e.target.value)}
        />
        <select
          className="input select"
          value={language}
          onChange={(e) =>
            setLanguage(e.target.value === "" ? "" : Number(e.target.value))
          }
        >
          <option value="">Language</option>
          {languages.map((l) => (
            <option key={l.id} value={l.id}>
              {l.name}
            </option>
          ))}
        </select>
      </div>
      <button
        type="submit"
        className="btn btn-primary"
        disabled={busy || !name.trim() || language === ""}
      >
        Create
      </button>
    </form>
  );
}

function DeckRow({
  deck,
  languages,
  busy,
  open,
  onToggle,
  onRename,
  onDelete,
  onStudy,
}: {
  deck: Deck;
  languages: Language[];
  busy: boolean;
  open: boolean;
  onToggle: () => void;
  onRename: (id: number, name: string) => void | Promise<void>;
  onDelete: (id: number) => void | Promise<void>;
  onStudy?: (deck: Deck) => void;
}) {
  const [editing, setEditing] = useState(false);
  const [name, setName] = useState(deck.name);

  const saveName = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;
    await onRename(deck.id, name.trim());
    setEditing(false);
  };

  const remove = () => {
    if (window.confirm(`Delete deck "${deck.name}" and all its cards?`)) {
      void onDelete(deck.id);
    }
  };

  if (editing) {
    return (
      <form className="deck-tile deck-tile--edit" onSubmit={saveName}>
        <input
          className="input"
          value={name}
          autoFocus
          onChange={(e) => setName(e.target.value)}
        />
        <button type="submit" className="btn btn-primary btn--sm" disabled={busy}>
          Save
        </button>
        <button
          type="button"
          className="btn btn--sm"
          onClick={() => {
            setName(deck.name);
            setEditing(false);
          }}
        >
          Cancel
        </button>
      </form>
    );
  }

  return (
    <div className={`deck-tile deck-tile--row ${open ? "is-open" : ""}`}>
      <button className="deck-tile__open" onClick={onToggle}>
        <span className="deck-badge">
          {deck.name.slice(0, 2).toUpperCase()}
        </span>
        <span className="deck-tile__main">
          <span className="deck-tile__name">
            {deck.name}
            <span className="chip">{langCode(languages, deck.language)}</span>
          </span>
          <span className="muted small">{deck.card_count} cards</span>
        </span>
        <span className="chevron">{open ? "⌄" : "›"}</span>
      </button>
      <div className="deck-tile__actions">
        {onStudy && deck.card_count > 0 && (
          <button
            className="icon-btn icon-btn--accent"
            aria-label={`Study ${deck.name}`}
            title="Study this deck"
            onClick={() => onStudy(deck)}
          >
            <PlayGlyph />
          </button>
        )}
        <button
          className="icon-btn"
          aria-label="Rename deck"
          onClick={() => setEditing(true)}
        >
          <PencilGlyph />
        </button>
        <button className="icon-btn" aria-label="Delete deck" onClick={remove}>
          <TrashGlyph />
        </button>
      </div>
    </div>
  );
}

function DeckCards({ deck }: { deck: Deck }) {
  const { cards, loading, busy, error, addCard, editCard, deleteCard } =
    useDeckCards(deck.id);

  return (
    <section className="card-panel">
      <h2 className="deck-group__title">Cards in {deck.name}</h2>
      {error && <div className="alert">{error}</div>}

      <AddCardForm busy={busy} onAdd={addCard} />

      {loading ? (
        <div className="screen--center" style={{ minHeight: 120 }}>
          <div className="spinner" />
        </div>
      ) : cards.length === 0 ? (
        <p className="muted" style={{ textAlign: "center", padding: "12px 0" }}>
          No cards yet — add your first one above.
        </p>
      ) : (
        <div className="card-list">
          {cards.map((card) => (
            <CardRow
              key={card.id}
              card={card}
              busy={busy}
              onEdit={editCard}
              onDelete={deleteCard}
            />
          ))}
        </div>
      )}
    </section>
  );
}

const EMPTY: CardPayload = {
  front: "",
  back: "",
  part_of_speech: "noun",
  example: "",
  description: "",
};

function AddCardForm({
  busy,
  onAdd,
}: {
  busy: boolean;
  onAdd: (payload: CardPayload) => void | Promise<void>;
}) {
  const [form, setForm] = useState<CardPayload>(EMPTY);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.front.trim() || !form.back.trim()) return;
    await onAdd({
      front: form.front.trim(),
      back: form.back.trim(),
      part_of_speech: form.part_of_speech,
      example: form.example?.trim(),
      description: form.description?.trim(),
    });
    setForm(EMPTY);
  };

  return (
    <form className="card mydeck-form" onSubmit={submit}>
      <div className="mydeck-form__row">
        <input
          className="input"
          placeholder="Front (term)"
          value={form.front}
          onChange={(e) => setForm({ ...form, front: e.target.value })}
        />
        <input
          className="input"
          placeholder="Back (translation)"
          value={form.back}
          onChange={(e) => setForm({ ...form, back: e.target.value })}
        />
      </div>
      <PosSelect
        value={form.part_of_speech ?? "noun"}
        onChange={(pos) => setForm({ ...form, part_of_speech: pos })}
      />
      <input
        className="input"
        placeholder="Example (optional)"
        value={form.example}
        onChange={(e) => setForm({ ...form, example: e.target.value })}
      />
      <input
        className="input"
        placeholder="Description (optional)"
        value={form.description}
        onChange={(e) => setForm({ ...form, description: e.target.value })}
      />
      <button
        type="submit"
        className="btn btn-primary"
        disabled={busy || !form.front.trim() || !form.back.trim()}
      >
        Add card
      </button>
    </form>
  );
}

function CardRow({
  card,
  busy,
  onEdit,
  onDelete,
}: {
  card: Card;
  busy: boolean;
  onEdit: (id: number, payload: Partial<CardPayload>) => void | Promise<void>;
  onDelete: (id: number) => void | Promise<void>;
}) {
  const [editing, setEditing] = useState(false);
  const [form, setForm] = useState<CardPayload>({
    front: card.front,
    back: card.back,
    part_of_speech: card.part_of_speech,
    example: card.example,
    description: card.description,
  });

  const save = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.front.trim() || !form.back.trim()) return;
    await onEdit(card.id, {
      front: form.front.trim(),
      back: form.back.trim(),
      part_of_speech: form.part_of_speech,
      example: form.example?.trim(),
      description: form.description?.trim(),
    });
    setEditing(false);
  };

  const remove = () => {
    if (window.confirm(`Delete card "${card.front}"?`)) void onDelete(card.id);
  };

  if (editing) {
    return (
      <form className="card-item card-item--edit" onSubmit={save}>
        <div className="mydeck-form__row">
          <input
            className="input"
            value={form.front}
            onChange={(e) => setForm({ ...form, front: e.target.value })}
          />
          <input
            className="input"
            value={form.back}
            onChange={(e) => setForm({ ...form, back: e.target.value })}
          />
        </div>
        <PosSelect
          value={form.part_of_speech ?? "noun"}
          onChange={(pos) => setForm({ ...form, part_of_speech: pos })}
        />
        <input
          className="input"
          placeholder="Example"
          value={form.example}
          onChange={(e) => setForm({ ...form, example: e.target.value })}
        />
        <input
          className="input"
          placeholder="Description"
          value={form.description}
          onChange={(e) => setForm({ ...form, description: e.target.value })}
        />
        <div className="card-item__actions">
          <button type="submit" className="btn btn-primary btn--sm" disabled={busy}>
            Save
          </button>
          <button
            type="button"
            className="btn btn--sm"
            onClick={() => setEditing(false)}
          >
            Cancel
          </button>
        </div>
      </form>
    );
  }

  return (
    <div className="card-item">
      <div className="card-item__main">
        <span className="card-item__terms">
          <strong>{card.front}</strong>
          <span className="chevron">→</span>
          <span className="term--answer">{card.back}</span>
        </span>
        <span className="chip">{card.part_of_speech}</span>
      </div>
      <div className="card-item__actions">
        <button
          className="icon-btn"
          aria-label="Edit card"
          onClick={() => setEditing(true)}
        >
          <PencilGlyph />
        </button>
        <button className="icon-btn" aria-label="Delete card" onClick={remove}>
          <TrashGlyph />
        </button>
      </div>
    </div>
  );
}

function PosSelect({
  value,
  onChange,
}: {
  value: PartOfSpeech;
  onChange: (pos: PartOfSpeech) => void;
}) {
  return (
    <select
      className="input select"
      value={value}
      onChange={(e) => onChange(e.target.value as PartOfSpeech)}
    >
      {POS_OPTIONS.map((pos) => (
        <option key={pos} value={pos}>
          {pos}
        </option>
      ))}
    </select>
  );
}

function PlayGlyph() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" aria-hidden>
      <path d="M7 5l12 7-12 7V5z" fill="currentColor" />
    </svg>
  );
}

function PencilGlyph() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" aria-hidden>
      <path
        d="M16.5 4.5l3 3L8 19l-4 1 1-4L16.5 4.5z"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinejoin="round"
      />
    </svg>
  );
}

function TrashGlyph() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" aria-hidden>
      <path
        d="M4 7h16M9 7V5a1 1 0 011-1h4a1 1 0 011 1v2m-9 0l1 13a1 1 0 001 1h6a1 1 0 001-1l1-13"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}
