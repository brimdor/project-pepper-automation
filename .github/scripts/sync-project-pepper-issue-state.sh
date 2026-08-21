#!/usr/bin/env bash
set -euo pipefail

: "${GH_TOKEN:?PROJECT_PEPPER_TOKEN is not configured}"
: "${PROJECT_OWNER:?PROJECT_OWNER is not configured}"
: "${PROJECT_NUMBER:?PROJECT_NUMBER is not configured}"
: "${DONE_STATUS:=Done}"

query='query($owner: String!, $number: Int!, $endCursor: String) {
  user(login: $owner) {
    projectV2(number: $number) {
      items(first: 100, after: $endCursor) {
        nodes {
          status: fieldValueByName(name: "Status") {
            ... on ProjectV2ItemFieldSingleSelectValue { name }
          }
          content {
            __typename
            ... on Issue {
              number
              state
              repository { nameWithOwner }
            }
          }
        }
        pageInfo { hasNextPage endCursor }
      }
    }
  }
}'

while IFS=$'\t' read -r repository number state status; do
  if [[ "$status" == "$DONE_STATUS" && "$state" == "OPEN" ]]; then
    echo "Closing $repository#$number because its status is $DONE_STATUS"
    gh api --method PATCH "repos/$repository/issues/$number" \
      -f state=closed -f state_reason=completed >/dev/null
  elif [[ "$status" != "$DONE_STATUS" && "$state" == "CLOSED" ]]; then
    display_status="${status:-No Status}"
    echo "Reopening $repository#$number because its status is $display_status"
    gh api --method PATCH "repos/$repository/issues/$number" \
      -f state=open >/dev/null
  fi
done < <(
  gh api graphql --paginate -f query="$query" \
    -f owner="$PROJECT_OWNER" -F number="$PROJECT_NUMBER" |
    jq -r '
      .data.user.projectV2.items.nodes[]
      | select(.content.__typename == "Issue")
      | [
          .content.repository.nameWithOwner,
          (.content.number | tostring),
          .content.state,
          (.status.name // "")
        ]
      | @tsv
    '
)
