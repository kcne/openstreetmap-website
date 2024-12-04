document.addEventListener("DOMContentLoaded", function () {
  console.log("[Cal-Heatmap]: DOMContentLoaded triggered.");

  if (typeof CalHeatMap === "undefined") {
    console.error("[Cal-Heatmap]: Library not loaded! Ensure cal-heatmap.js is included.");
    return;
  }

  console.log("[Cal-Heatmap]: Library successfully loaded.");

  const heatmapElement = document.querySelector('#cellRadius-a');
  const heatmapDataElement = document.querySelector('#heatmap-data');

  if (!heatmapElement) {
    console.error("[Cal-Heatmap]: Element with ID '#cellRadius-a' not found in the DOM.");
    return;
  }

  if (!heatmapDataElement) {
    console.error("[Cal-Heatmap]: Element with ID '#heatmap-data' not found in the DOM.");
    return;
  }

  // Retrieve heatmap data from the hidden element
  const heatmapData = JSON.parse(heatmapDataElement.getAttribute('data-heatmap') || '{}');
  console.log("[Cal-Heatmap]: Heatmap data loaded:", heatmapData);

  try {
    console.log("[Cal-Heatmap]: Initializing...");
    var cal = new CalHeatMap();
    cal.init({
      itemSelector: '#cellRadius-a', // Target element for the heatmap
      domain: 'month',               // Display data by year
      subDomain: 'day',             // Subdomain granularity (days)
      data: heatmapData,            // Pass heatmap data here
      cellRadius:3,
      start: new Date(new Date().getFullYear(), 0), // Start at the beginning of the year
      cellSize: 10,                 // Size of individual cells
      range: 12,                     // Number of years to display
      legend: [1, 2, 3, 4],       // Legend intervals for heatmap values
      displayLegend: true,          // Show legend
      tooltip: true,                // Enable tooltips
    });
    console.log("[Cal-Heatmap]: Initialization successful.");
  } catch (error) {
    console.error("[Cal-Heatmap]: E1rror during initialization:", error);
  }
});
