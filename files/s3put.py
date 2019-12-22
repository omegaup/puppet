#!/usr/bin/python3
"""Pure Python implementation of the Amazon S3 REST API."""
# pylint: disable=invalid-name,too-many-locals

import base64
import datetime
import hashlib
import hmac
import http.client
import logging

from typing import Optional, Tuple

_EMPTY_SHA256_HASH = ('e3b0c44298fc1c149afbf4c8996fb924'
                      '27ae41e4649b934ca495991b7852b855')


def _hash(path: str) -> Tuple[str, str, int]:
    sha = hashlib.sha256()
    md5 = hashlib.md5()
    length = 0
    with open(path, 'rb') as file_stream:
        while True:
            block = file_stream.read(4096)
            if not block:
                break
            sha.update(block)
            md5.update(block)
            length += len(block)
    return (sha.hexdigest(), base64.b64encode(md5.digest()).decode('utf-8'),
            length)


class S3:
    """Pure Python implementation of the Amazon S3 REST API."""
    def __init__(self,
                 bucket: str,
                 aws_access_key: str,
                 secret_access_key: str,
                 region: str = 'us-east-1') -> None:
        self.bucket = bucket
        self.conn: Optional[http.client.HTTPSConnection] = None
        self.aws_access_key = aws_access_key
        now = datetime.datetime.utcnow()
        date = now.strftime('%Y%m%d')

        self.scope = '%s/%s/s3/aws4_request' % (date, region)

        date_key = hmac.new(b'AWS4' + secret_access_key.encode('utf-8'),
                            date.encode('utf-8'),
                            digestmod='sha256').digest()
        date_region_key = hmac.new(date_key,
                                   region.encode('utf-8'),
                                   digestmod='sha256').digest()
        date_region_service_key = hmac.new(date_region_key,
                                           b's3',
                                           digestmod='sha256').digest()
        self.signing_key = hmac.new(date_region_service_key,
                                    b'aws4_request',
                                    digestmod='sha256').digest()

    def put(self, path: str, filename: str) -> None:
        """Uploads the local file `path` as `filename`."""

        payload_hash, content_md5, length = _hash(path)

        now = datetime.datetime.utcnow()
        timestamp = now.strftime('%Y%m%dT%H%M%SZ')
        headers = [
            ('Connection', 'keep-alive'),
            ('Content-Length', str(length)),
            ('Content-MD5', content_md5),
            ('Content-Type', 'application/zip'),
            ('Date', now.strftime('%a, %d %b %Y %H:%M:%S GMT')),
            ('Host', '%s.s3.amazonaws.com' % self.bucket),
            ('x-amz-content-sha256', payload_hash),
            ('x-amz-date', timestamp),
        ]
        signed_headers = ';'.join(header[0].lower() for header in headers)
        canonical_request = 'PUT\n%s\n\n%s\n\n%s\n%s' % (filename, '\n'.join(
            ('%s:%s' % (header[0].lower(), header[1])
             for header in headers)), signed_headers, payload_hash)
        logging.debug('canonical request %r',
                      canonical_request.encode('utf-8'))
        string_to_sign = 'AWS4-HMAC-SHA256\n%s\n%s\n%s' % (
            timestamp, self.scope,
            hashlib.sha256(canonical_request.encode('utf-8')).hexdigest())
        logging.debug('string to sign %r', string_to_sign.encode('utf-8'))

        signature = hmac.new(self.signing_key,
                             string_to_sign.encode('utf-8'),
                             digestmod='sha256').hexdigest()
        headers.append((
            'Authorization',
            'AWS4-HMAC-SHA256 Credential=%s/%s,SignedHeaders=%s,Signature=%s' %
            (self.aws_access_key, self.scope, signed_headers, signature)))
        with open(path, 'rb') as file_stream:
            if not self.conn:
                self.conn = http.client.HTTPSConnection('%s.s3.amazonaws.com' %
                                                        self.bucket)
            try:
                self.conn.request('PUT',
                                  filename,
                                  file_stream,
                                  headers=dict(headers))
                res = self.conn.getresponse()
                payload = res.read()
            except (http.client.BadStatusLine, http.client.ResponseNotReady,
                    http.client.CannotSendRequest):
                self.conn.close()
                raise
            if res.status != 200:
                raise Exception(payload.decode('utf-8'))

    def mv(self, source: str, filename: str) -> None:
        """Renames the remote object `source` as `filename`."""

        self.cp(source, filename)
        self.rm(source)

    def cp(self, source: str, filename: str) -> None:
        """Copies the remote object `source` as `filename`."""

        now = datetime.datetime.utcnow()
        timestamp = now.strftime('%a, %d %b %Y %H:%M:%S GMT')
        headers = [
            ('Connection', 'keep-alive'),
            ('Content-Length', '0'),
            ('Date', timestamp),
            ('Host', '%s.s3.amazonaws.com' % self.bucket),
            ('x-amz-content-sha256', _EMPTY_SHA256_HASH),
            ('x-amz-copy-source', '/%s%s' % (self.bucket, source)),
        ]
        signed_headers = ';'.join(header[0].lower() for header in headers)
        canonical_request = 'PUT\n%s\n\n%s\n\n%s\n%s' % (filename, '\n'.join(
            ('%s:%s' % (header[0].lower(), header[1])
             for header in headers)), signed_headers, _EMPTY_SHA256_HASH)
        logging.debug('canonical request %r',
                      canonical_request.encode('utf-8'))
        string_to_sign = 'AWS4-HMAC-SHA256\n%s\n%s\n%s' % (
            timestamp, self.scope,
            hashlib.sha256(canonical_request.encode('utf-8')).hexdigest())
        logging.debug('string to sign %r', string_to_sign.encode('utf-8'))

        signature = hmac.new(self.signing_key,
                             string_to_sign.encode('utf-8'),
                             digestmod='sha256').hexdigest()
        headers.append((
            'Authorization',
            'AWS4-HMAC-SHA256 Credential=%s/%s,SignedHeaders=%s,Signature=%s' %
            (self.aws_access_key, self.scope, signed_headers, signature)))
        if not self.conn:
            self.conn = http.client.HTTPSConnection('%s.s3.amazonaws.com' %
                                                    self.bucket)
        try:
            self.conn.request('PUT', filename, headers=dict(headers))
            res = self.conn.getresponse()
            payload = res.read()
        except (http.client.BadStatusLine, http.client.ResponseNotReady,
                http.client.CannotSendRequest):
            self.conn.close()
            raise
        if res.status != 200:
            raise Exception(payload.decode('utf-8'))

    def rm(self, filename: str) -> None:
        """Deletes the remote object `filename`."""

        now = datetime.datetime.utcnow()
        timestamp = now.strftime('%a, %d %b %Y %H:%M:%S GMT')
        headers = [
            ('Connection', 'keep-alive'),
            ('Content-Length', '0'),
            ('Date', timestamp),
            ('Host', '%s.s3.amazonaws.com' % self.bucket),
            ('x-amz-content-sha256', _EMPTY_SHA256_HASH),
        ]
        signed_headers = ';'.join(header[0].lower() for header in headers)
        canonical_request = 'DELETE\n%s\n\n%s\n\n%s\n%s' % (
            filename, '\n'.join(
                ('%s:%s' % (header[0].lower(), header[1])
                 for header in headers)), signed_headers, _EMPTY_SHA256_HASH)
        logging.debug('canonical request %r',
                      canonical_request.encode('utf-8'))
        string_to_sign = 'AWS4-HMAC-SHA256\n%s\n%s\n%s' % (
            timestamp, self.scope,
            hashlib.sha256(canonical_request.encode('utf-8')).hexdigest())
        logging.debug('string to sign %r', string_to_sign.encode('utf-8'))

        signature = hmac.new(self.signing_key,
                             string_to_sign.encode('utf-8'),
                             digestmod='sha256').hexdigest()
        headers.append((
            'Authorization',
            'AWS4-HMAC-SHA256 Credential=%s/%s,SignedHeaders=%s,Signature=%s' %
            (self.aws_access_key, self.scope, signed_headers, signature)))
        if not self.conn:
            self.conn = http.client.HTTPSConnection('%s.s3.amazonaws.com' %
                                                    self.bucket)
        try:
            self.conn.request('DELETE', filename, headers=dict(headers))
            res = self.conn.getresponse()
            payload = res.read()
        except (http.client.BadStatusLine, http.client.ResponseNotReady,
                http.client.CannotSendRequest):
            self.conn.close()
            raise
        if res.status != 204:
            raise Exception(payload.decode('utf-8'))
