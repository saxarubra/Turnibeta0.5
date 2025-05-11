import {
  Body,
  Button,
  Container,
  Head,
  Heading,
  Html,
  Link,
  Preview,
  Section,
  Text,
} from '@react-email/components';
import * as React from 'react';

interface SwapRequestEmailProps {
  requesterName: string;
  requestedName: string;
  requesterShift: string;
  requestedShift: string;
  swapId: string;
  baseUrl: string;
}

export const SwapRequestEmail = ({
  requesterName,
  requestedName,
  requesterShift,
  requestedShift,
  swapId,
  baseUrl,
}: SwapRequestEmailProps) => {
  const backendBaseUrl = baseUrl;
  const authorizeUrl = `${backendBaseUrl}/api/swaps/${swapId}/authorize`;
  const rejectUrl = `${backendBaseUrl}/api/swaps/${swapId}/reject`;

  return (
    <Html>
      <Head />
      <Preview>Richiesta di autorizzazione scambio turno</Preview>
      <Body style={main}>
        <Container style={container}>
          <Heading style={h1}>Richiesta di Autorizzazione Scambio Turno</Heading>
          
          <Text style={text}>
            Ciao Admin,
          </Text>
          
          <Text style={text}>
            È stata proposta una richiesta di scambio turno:
          </Text>
          
          <Section style={detailsContainer}>
            <Text style={text}>
              <strong>Richiedente:</strong> {requesterName}
            </Text>
            <Text style={text}>
              <strong>Turno richiesto:</strong> {requestedShift}
            </Text>
            <Text style={text}>
              <strong>Dipendente richiesto:</strong> {requestedName}
            </Text>
            <Text style={text}>
              <strong>Turno offerto:</strong> {requesterShift}
            </Text>
          </Section>

          <Text style={text}>
            Per autorizzare o rifiutare questa richiesta, clicca sui pulsanti qui sotto:
          </Text>

          <Section style={buttonContainer}>
            <Button
              style={acceptButton}
              href={authorizeUrl}
            >
              Autorizza Scambio
            </Button>
            <Button
              style={rejectButton}
              href={rejectUrl}
            >
              Rifiuta Scambio
            </Button>
          </Section>

          <Text style={footer}>
            Se i pulsanti non funzionano, puoi copiare e incollare questi link nel tuo browser:
            <br />
            Autorizza: {authorizeUrl}
            <br />
            Rifiuta: {rejectUrl}
          </Text>
        </Container>
      </Body>
    </Html>
  );
};

const main = {
  backgroundColor: '#ffffff',
  fontFamily: '-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Oxygen-Sans,Ubuntu,Cantarell,"Helvetica Neue",sans-serif',
};

const container = {
  margin: '0 auto',
  padding: '20px 0 48px',
  maxWidth: '580px',
};

const h1 = {
  color: '#1a1a1a',
  fontSize: '24px',
  fontWeight: '600',
  lineHeight: '1.25',
  margin: '16px 0',
};

const text = {
  color: '#444444',
  fontSize: '16px',
  lineHeight: '1.5',
  margin: '16px 0',
};

const detailsContainer = {
  backgroundColor: '#f9f9f9',
  padding: '16px',
  borderRadius: '4px',
  margin: '16px 0',
};

const buttonContainer = {
  display: 'flex',
  justifyContent: 'space-between',
  margin: '24px 0',
};

const acceptButton = {
  backgroundColor: '#22c55e',
  color: '#ffffff',
  borderRadius: '4px',
  textDecoration: 'none',
  padding: '12px 20px',
};

const rejectButton = {
  backgroundColor: '#ef4444',
  color: '#ffffff',
  borderRadius: '4px',
  textDecoration: 'none',
  padding: '12px 20px',
};

const footer = {
  color: '#666666',
  fontSize: '14px',
  lineHeight: '1.5',
  margin: '24px 0',
};

export default SwapRequestEmail; 