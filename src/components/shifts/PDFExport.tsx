import React from 'react';
import { Page, Text, View, Document, StyleSheet, PDFDownloadLink } from '@react-pdf/renderer';

// Stili per il PDF
const styles = StyleSheet.create({
  page: {
    flexDirection: 'column',
    backgroundColor: '#ffffff',
    padding: 30,
  },
  title: {
    fontSize: 20,
    marginBottom: 20,
    textAlign: 'center',
  },
  table: {
    display: 'table',
    width: '100%',
    borderStyle: 'solid',
    borderWidth: 1,
    borderColor: '#000',
  },
  tableRow: {
    flexDirection: 'row',
    borderBottomWidth: 1,
    borderBottomColor: '#000',
  },
  tableCell: {
    width: '12.5%', // 8 colonne (1 per dipendente + 7 giorni)
    padding: 5,
    borderRightWidth: 1,
    borderRightColor: '#000',
    fontSize: 10,
  },
  headerCell: {
    width: '12.5%',
    padding: 5,
    borderRightWidth: 1,
    borderRightColor: '#000',
    backgroundColor: '#f0f0f0',
    fontSize: 10,
    fontWeight: 'bold',
  },
});

// Componente per il documento PDF
const ShiftsPDF = ({ matrix }) => (
  <Document>
    <Page size="A4" style={styles.page}>
      <Text style={styles.title}>Matrice dei Turni</Text>
      <View style={styles.table}>
        {matrix.map((row, rowIndex) => (
          <View key={rowIndex} style={styles.tableRow}>
            {row.map((cell, cellIndex) => {
              const CellStyle = rowIndex === 0 ? styles.headerCell : styles.tableCell;
              return (
                <Text key={cellIndex} style={CellStyle}>
                  {cell || '-'}
                </Text>
              );
            })}
          </View>
        ))}
      </View>
    </Page>
  </Document>
);

// Componente per il pulsante di download
const PDFExport = ({ matrix }) => (
  <PDFDownloadLink
    document={<ShiftsPDF matrix={matrix} />}
    fileName="turni.pdf"
    style={{
      textDecoration: 'none',
      padding: '10px 20px',
      color: '#fff',
      backgroundColor: '#007bff',
      border: 'none',
      borderRadius: '4px',
      cursor: 'pointer',
      display: 'inline-block',
      marginTop: '20px',
    }}
  >
    {({ blob, url, loading, error }) =>
      loading ? 'Generazione PDF...' : 'Scarica PDF'
    }
  </PDFDownloadLink>
);

export default PDFExport; 