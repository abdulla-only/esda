import type { Deck } from "../../shared/api/types";
import { useDeckTree } from "./useDeckTree";

function DeckTile({
  deck,
  langCode,
  onStudy,
}: {
  deck: Deck;
  langCode: string;
  onStudy: (deckId: number) => void;
}) {
  return (
    <>
      <button className="deck-tile" onClick={() => onStudy(deck.id)}>
        <span className="deck-badge">{deck.name.slice(0, 2).toUpperCase()}</span>
        <span className="deck-tile__main">
          <span className="deck-tile__name">
            {deck.name}
            <span className="chip">{langCode.toUpperCase()}</span>
          </span>
          <span className="muted small">{deck.card_count} cards</span>
        </span>
        <span className="chevron">›</span>
      </button>
      {deck.children?.map((child) => (
        <div key={child.id} style={{ marginLeft: 18 }}>
          <DeckTile deck={child} langCode={langCode} onStudy={onStudy} />
        </div>
      ))}
    </>
  );
}

export function Decks({ onStudy }: { onStudy: (deckId: number) => void }) {
  const { groups, loading } = useDeckTree();

  if (loading) {
    return (
      <div className="screen screen--center">
        <div className="spinner" />
      </div>
    );
  }

  return (
    <div className="screen">
      <h1 className="screen__title">Decks</h1>
      {groups.map((group) => (
        <div className="deck-group" key={group.language.id}>
          <h2 className="deck-group__title">{group.language.name}</h2>
          <div className="deck-list">
            {group.decks.map((deck) => (
              <DeckTile
                key={deck.id}
                deck={deck}
                langCode={group.language.code}
                onStudy={onStudy}
              />
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}
