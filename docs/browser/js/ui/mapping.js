/* ui/mapping.js
 * -------------------------------------------------------------
 * Displays the static “Relationships & Synonyms” section below
 * the table when a concept row is clicked.
 * Relies on store.relationships & store.synonyms (lazy‑loaded).
 * ------------------------------------------------------------- */

import { store } from "../store.js";

/**
 * Displays static relationship/synonym info below the table (legacy mode)
 */
export function showStaticMapping(conceptId, conceptName) {
  const container     = document.querySelector("#relationship-display");
  const title         = container.querySelector("h2 span");
  const tbody         = container.querySelector("#relationship-table-body");
  const synonymList   = container.querySelector("#synonym-list");

  title.textContent = `${conceptId} – ${conceptName}`;
  tbody.innerHTML = "";
  synonymList.innerHTML = "";

  const rels = (store.relationships || []).filter(
    r => Number(r.concept_id_1) === conceptId
  );

  if (rels.length) {
    rels.forEach(r => {
      const c2 = store.concepts.find(c => c.concept_id == r.concept_id_2) || {};
      const row = document.createElement("tr");
      row.innerHTML = `
        <td>${r.relationship_id}</td>
        <td>${c2.concept_id || r.concept_id_2}</td>
        <td>${c2.concept_name || "-"}</td>`;
      tbody.appendChild(row);
    });
  } else {
    const row = document.createElement("tr");
    row.innerHTML = `<td colspan="3" style="text-align:center; color:#666;">
      No relationships found.
    </td>`;
    tbody.appendChild(row);
  }

  const syns = (store.synonyms || []).filter(
    s => String(s.concept_id).trim() === String(conceptId).trim()
  );

  if (syns.length) {
    syns.forEach(s => {
      const li = document.createElement("li");
      li.textContent = s.concept_synonym_name;
      synonymList.appendChild(li);
    });
  } else {
    const li = document.createElement("li");
    li.textContent = "No synonyms found.";
    synonymList.appendChild(li);
  }

  container.classList.remove("hidden");
}

/**
 * Renders relationships & synonyms inline (in table row below selected)
 * Returns a <tr> element to be inserted by the caller.
 */
export function renderInlineMapping(conceptId, conceptName, rowEl) {
  document.querySelectorAll(".inline-mapping-row").forEach(r => r.remove());

  const mappingRow = document.createElement("tr");
  mappingRow.className = "inline-mapping-row";

  const td = document.createElement("td");
  td.colSpan = 9;
  td.style.backgroundColor = "#fcfcfc";
  td.style.padding = "15px";

  const wrapper = document.createElement("div");
  wrapper.classList.add("relationship-container");

  const title = document.createElement("h2");
  title.textContent = `Relationships & Synonyms for: ${conceptId} — ${conceptName}`;
  wrapper.appendChild(title);

  // Relationships
  const rels = (store.relationships || []).filter(
    r => String(r.concept_id_1) === String(conceptId)
  );

  const relTable = document.createElement("table");
  relTable.classList.add("relationship-table");
  relTable.innerHTML = `
    <thead>
      <tr>
        <th>relationship_id</th>
        <th>concept_id_2</th>
        <th>concept_name</th>
      </tr>
    </thead>
    <tbody>
      ${
        rels.length
          ? rels.map(r => {
              const c2 = store.concepts.find(c => c.concept_id == r.concept_id_2) || {};
              return `
                <tr>
                  <td>${r.relationship_id}</td>
                  <td>${c2.concept_id || r.concept_id_2}</td>
                  <td>${c2.concept_name || "-"}</td>
                </tr>`;
            }).join("")
          : `<tr><td colspan="3" style="text-align:center;">No relationships found.</td></tr>`
      }
    </tbody>
  `;
  wrapper.appendChild(relTable);

  // Synonyms
  const syns = (store.synonyms || []).filter(
    s => String(s.concept_id).trim() === String(conceptId).trim()
  );

  const synHeader = document.createElement("h3");
  synHeader.textContent = "Synonyms:";
  wrapper.appendChild(synHeader);

  const synList = document.createElement("ul");
  synList.style.listStyle = "none";
  synList.style.paddingLeft = "0";

  if (syns.length) {
    syns.forEach(s => {
      const li = document.createElement("li");
      li.textContent = s.concept_synonym_name;
      synList.appendChild(li);
    });
  } else {
    const li = document.createElement("li");
    li.textContent = "No synonyms found.";
    synList.appendChild(li);
  }

  wrapper.appendChild(synList);
  td.appendChild(wrapper);
  mappingRow.appendChild(td);

  return mappingRow;
}
