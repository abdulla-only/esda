import { Component, ErrorInfo, ReactNode } from "react";

interface State {
  error: Error | null;
}

/** Last-resort guard: shows a message instead of a blank page on a render crash. */
export class ErrorBoundary extends Component<{ children: ReactNode }, State> {
  state: State = { error: null };

  static getDerivedStateFromError(error: Error): State {
    return { error };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    console.error("esda crashed:", error, info);
  }

  render() {
    if (this.state.error) {
      return (
        <div className="page center">
          <h2>Something went wrong</h2>
          <p className="hint">{this.state.error.message}</p>
        </div>
      );
    }
    return this.props.children;
  }
}
